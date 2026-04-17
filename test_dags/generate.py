"""Generate deterministic test DAGs for the dag-downpacking pipeline.

Creates 11 dbt DAGs of varying size and shape (1 to 100 nodes) that exercise
the pipeline end-to-end.  Half have predictable slack patterns, half are mixed.

Usage:
    python test_dags/generate.py          # generate all test DAGs
    python test_dags/generate.py --clean   # wipe td_* models first
"""

import argparse
import os
import random
import textwrap

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
OUTPUT_DIR = os.path.join(PROJECT_DIR, "models", "generated")

# ---------------------------------------------------------------------------
# dbt model helpers (mirrors benchmark/generate_models.py)
# ---------------------------------------------------------------------------


def _config_block(materialized: str, tags: list[str]) -> str:
    tag_str = ", ".join(f"'{t}'" for t in ["generated"] + tags)
    return textwrap.dedent(f"""\
        {{{{
            config(
                materialized = '{materialized}',
                tags = [{tag_str}, 'sf' ~ var('sf', '10')]
            )
        }}}}""")


def _model_sql(body: str, tags: list[str]) -> str:
    wrapped = f"""
select *, '{{{{ var("sf", "10") }}}}' as _sf
from ({body}
) _q"""
    return _config_block("table", tags) + "\n" + wrapped


def _write_model(name: str, body: str, tags: list[str]) -> None:
    path = os.path.join(OUTPUT_DIR, f"{name}.sql")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(_model_sql(body, tags))


def _ref(name: str) -> str:
    return "{{ ref('" + name + "') }}"


# ---------------------------------------------------------------------------
# SQL templates by weight class
# ---------------------------------------------------------------------------


def _heavy_ods_scan(alias: str = "oi") -> str:
    """Full scan of orders_items with aggregation and window function (~5-15s)."""
    return f"""
select
    {alias}.customer_key,
    {alias}.order_key,
    sum({alias}.gross_item_sales_amount) over (
        partition by {alias}.customer_key
        order by {alias}.order_date
    ) as running_sales,
    count(*) over (partition by {alias}.customer_key) as customer_order_count,
    {alias}.gross_item_sales_amount,
    {alias}.discount_percentage,
    {alias}.order_date,
    {alias}.ship_date
from {_ref('orders_items')} {alias}"""


def _heavy_join() -> str:
    """Multi-table join (~5-10s)."""
    return f"""
select
    oi.customer_key,
    c.name as customer_name,
    c.nation_key,
    sum(oi.gross_item_sales_amount) as total_sales,
    count(*) as line_count,
    avg(oi.discount_percentage) as avg_discount
from {_ref('orders_items')} oi
join {_ref('customers')} c on oi.customer_key = c.customer_key
group by 1, 2, 3"""


def _medium_agg_upstream(upstream: str) -> str:
    """Aggregate upstream output (~1-5s)."""
    return f"""
select
    customer_key,
    count(*) as row_count,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {_ref(upstream)}
group by 1"""


def _medium_filter_upstream(upstream: str) -> str:
    """Filter upstream output (~1-3s)."""
    return f"""
select *
from {_ref(upstream)}
where gross_item_sales_amount > 1000
  and discount_percentage < 0.1"""


def _light_count_upstream(upstream: str) -> str:
    """Simple count of upstream (~<1s)."""
    return f"""
select count(*) as total_rows, sum(total_sales) as grand_total
from {_ref(upstream)}"""


def _light_select_upstream(upstream: str, limit: int = 100) -> str:
    """Select from upstream with limit (~<1s)."""
    return f"""
select * from {_ref(upstream)} limit {limit}"""


def _light_nations() -> str:
    """Scan nations table (25 rows, ~<1s)."""
    return f"""
select * from {_ref('nations')}"""


def _join_upstreams(upstreams: list[str]) -> str:
    """Join 2-3 upstream tables on customer_key (~light)."""
    base = upstreams[0]
    sql = f"select a.* from {_ref(base)} a"
    for i, up in enumerate(upstreams[1:], 1):
        alias = chr(ord("a") + i)
        sql += f"\njoin {_ref(up)} {alias} on a.customer_key = {alias}.customer_key"
    return sql


def _union_upstreams(upstreams: list[str]) -> str:
    """Union upstream tables (~light)."""
    parts = [f"select *, '{up}' as _source from {_ref(up)}" for up in upstreams]
    return "\nunion all\n".join(parts)


# ---------------------------------------------------------------------------
# Hand-crafted DAGs (1-15 nodes)
# ---------------------------------------------------------------------------
# Each DAG is a list of (model_name, sql_body) tuples.
# The tag for each DAG is the DAG name itself (e.g., "td_solo_heavy").
# Models are written in dependency order.


def _dag_solo_heavy() -> list[tuple[str, str]]:
    """1 node: single heavy query."""
    return [("td_solo_heavy_n1", _heavy_ods_scan())]


def _dag_solo_light() -> list[tuple[str, str]]:
    """1 node: single light query."""
    return [("td_solo_light_n1", _light_nations())]


def _dag_chain3_slack() -> list[tuple[str, str]]:
    """3 nodes: heavy -> medium -> light (clear slack gradient)."""
    return [
        ("td_chain3_slack_n1", _heavy_ods_scan()),
        ("td_chain3_slack_n2", _medium_agg_upstream("td_chain3_slack_n1")),
        ("td_chain3_slack_n3", _light_count_upstream("td_chain3_slack_n2")),
    ]


def _dag_fan3_mixed() -> list[tuple[str, str]]:
    """3 nodes: 1 root -> 2 asymmetric leaves."""
    return [
        ("td_fan3_mixed_root", _heavy_join()),
        ("td_fan3_mixed_a", _medium_filter_upstream("td_fan3_mixed_root")),
        ("td_fan3_mixed_b", _light_count_upstream("td_fan3_mixed_root")),
    ]


def _dag_chain10_slack() -> list[tuple[str, str]]:
    """10 nodes: linear chain, monotonically decreasing complexity."""
    tag = "td_chain10_slack"
    nodes = []
    # n01: heavy ODS scan
    nodes.append((f"{tag}_n01", _heavy_ods_scan()))
    # n02: heavy join with customers
    nodes.append((f"{tag}_n02", f"""
select a.*, c.name as customer_name
from {_ref(f'{tag}_n01')} a
join {_ref('customers')} c on a.customer_key = c.customer_key"""))
    # n03: medium aggregation
    nodes.append((f"{tag}_n03", _medium_agg_upstream(f"{tag}_n02")))
    # n04: medium filter
    nodes.append((f"{tag}_n04", _medium_filter_upstream(f"{tag}_n02")))
    # n05: join n03 and n04
    nodes.append((f"{tag}_n05", _join_upstreams([f"{tag}_n03", f"{tag}_n04"])))
    # n06-n08: progressively lighter
    nodes.append((f"{tag}_n06", f"select *, row_count * 2 as doubled from {_ref(f'{tag}_n05')}"))
    nodes.append((f"{tag}_n07", f"select * from {_ref(f'{tag}_n06')} where row_count > 5"))
    nodes.append((f"{tag}_n08", f"select count(*) as cnt from {_ref(f'{tag}_n07')}"))
    # n09-n10: trivial
    nodes.append((f"{tag}_n09", f"select cnt, cnt + 1 as cnt_plus from {_ref(f'{tag}_n08')}"))
    nodes.append((f"{tag}_n10", f"select * from {_ref(f'{tag}_n09')} limit 1"))
    return nodes


def _dag_diamond10_mixed() -> list[tuple[str, str]]:
    """10 nodes: diamond/lattice pattern with merges."""
    tag = "td_diamond10_mixed"
    return [
        # Layer 0: source
        (f"{tag}_src", _heavy_ods_scan()),
        # Layer 1: fan-out
        (f"{tag}_a1", _medium_agg_upstream(f"{tag}_src")),
        (f"{tag}_a2", _medium_filter_upstream(f"{tag}_src")),
        (f"{tag}_a3", f"select * from {_ref(f'{tag}_src')} where order_date > '1995-01-01'"),
        (f"{tag}_a4", f"select customer_key, count(*) as cnt from {_ref(f'{tag}_src')} group by 1"),
        # Layer 2: merges
        (f"{tag}_b1", _join_upstreams([f"{tag}_a1", f"{tag}_a2"])),
        (f"{tag}_b2", _join_upstreams([f"{tag}_a2", f"{tag}_a3"])),
        (f"{tag}_b3", _join_upstreams([f"{tag}_a3", f"{tag}_a4"])),
        # Layer 3: sink
        (f"{tag}_sink", _union_upstreams([f"{tag}_b1", f"{tag}_b2", f"{tag}_b3"])),
        # Extra node for 10 total
        (f"{tag}_final", _light_count_upstream(f"{tag}_sink")),
    ]


def _dag_wide10_slack() -> list[tuple[str, str]]:
    """10 nodes: 1 source -> 8 workers (varied weight) -> 1 sink."""
    tag = "td_wide10_slack"
    nodes = [
        (f"{tag}_src", _heavy_join()),
    ]
    # 8 workers with decreasing complexity
    worker_sqls = [
        # w1: heavy (window function on full upstream)
        f"""select *, row_number() over (order by total_sales desc) as rank
from {_ref(f'{tag}_src')}""",
        # w2: medium (aggregation)
        f"select nation_key, sum(total_sales) as nation_sales from {_ref(f'{tag}_src')} group by 1",
        # w3: medium (filter)
        f"select * from {_ref(f'{tag}_src')} where total_sales > 50000",
        # w4: medium-light
        f"select customer_key, total_sales from {_ref(f'{tag}_src')} where line_count > 100",
        # w5-w8: light
        f"select count(*) as cnt from {_ref(f'{tag}_src')}",
        f"select max(total_sales) as max_sales from {_ref(f'{tag}_src')}",
        f"select min(total_sales) as min_sales from {_ref(f'{tag}_src')}",
        f"select avg(avg_discount) as mean_discount from {_ref(f'{tag}_src')}",
    ]
    for i, sql in enumerate(worker_sqls, 1):
        nodes.append((f"{tag}_w{i}", sql))

    # Sink: union all workers (just counts to keep it light)
    sink_parts = " union all ".join(
        f"select '{tag}_w{i}' as worker, count(*) as n from {_ref(f'{tag}_w{i}')}"
        for i in range(1, 9)
    )
    nodes.append((f"{tag}_sink", sink_parts))
    return nodes


def _dag_tree10_mixed() -> list[tuple[str, str]]:
    """10 nodes: binary tree with uniform-ish timing."""
    tag = "td_tree10_mixed"
    return [
        # Root
        (f"{tag}_root", f"""
select customer_key, order_key, gross_item_sales_amount, order_date
from {_ref('orders_items')}
where order_date > '1996-01-01'"""),
        # Level 1
        (f"{tag}_l1a", f"""
select customer_key, sum(gross_item_sales_amount) as total
from {_ref(f'{tag}_root')} group by 1"""),
        (f"{tag}_l1b", f"""
select order_key, count(*) as items
from {_ref(f'{tag}_root')} group by 1"""),
        # Level 2
        (f"{tag}_l2a", f"select * from {_ref(f'{tag}_l1a')} where total > 10000"),
        (f"{tag}_l2b", f"select customer_key, total * 1.1 as adjusted from {_ref(f'{tag}_l1a')}"),
        (f"{tag}_l2c", f"select * from {_ref(f'{tag}_l1b')} where items > 3"),
        (f"{tag}_l2d", f"select order_key, items * 2 as doubled from {_ref(f'{tag}_l1b')}"),
        # Level 3 (leaves)
        (f"{tag}_l3a", _light_count_upstream(f"{tag}_l2a")),
        (f"{tag}_l3b", _light_count_upstream(f"{tag}_l2b")),
        (f"{tag}_l3c", _light_count_upstream(f"{tag}_l2c")),
    ]


def _dag_pipeline15_slack() -> list[tuple[str, str]]:
    """15 nodes: 3 parallel chains (heavy/medium/light) merged at end."""
    tag = "td_pipeline15_slack"
    nodes = []

    # Chain A: heavy (5 nodes)
    nodes.append((f"{tag}_a1", _heavy_ods_scan()))
    nodes.append((f"{tag}_a2", f"""
select customer_key, sum(gross_item_sales_amount) as total,
       count(*) as cnt
from {_ref(f'{tag}_a1')} group by 1"""))
    nodes.append((f"{tag}_a3", f"""
select a.*, c.name from {_ref(f'{tag}_a2')} a
join {_ref('customers')} c on a.customer_key = c.customer_key"""))
    nodes.append((f"{tag}_a4", f"""
select *, row_number() over (order by total desc) as rank
from {_ref(f'{tag}_a3')}"""))
    nodes.append((f"{tag}_a5", f"select * from {_ref(f'{tag}_a4')} where rank <= 1000"))

    # Chain B: medium (5 nodes)
    nodes.append((f"{tag}_b1", f"""
select order_key, customer_key, order_date, total_price
from {_ref('orders')}"""))
    nodes.append((f"{tag}_b2", f"""
select customer_key, count(*) as order_count
from {_ref(f'{tag}_b1')} group by 1"""))
    nodes.append((f"{tag}_b3", f"select * from {_ref(f'{tag}_b2')} where order_count > 5"))
    nodes.append((f"{tag}_b4", f"select customer_key, order_count * 10 as score from {_ref(f'{tag}_b3')}"))
    nodes.append((f"{tag}_b5", _light_count_upstream(f"{tag}_b4")))

    # Chain C: light (4 nodes)
    nodes.append((f"{tag}_c1", _light_nations()))
    nodes.append((f"{tag}_c2", f"select nation_key, name from {_ref(f'{tag}_c1')}"))
    nodes.append((f"{tag}_c3", f"select count(*) as nation_count from {_ref(f'{tag}_c2')}"))
    nodes.append((f"{tag}_c4", f"select nation_count, nation_count + 1 as plus1 from {_ref(f'{tag}_c3')}"))

    # Merge node
    nodes.append((f"{tag}_merge", f"""
select 'a' as chain, count(*) as n from {_ref(f'{tag}_a5')}
union all
select 'b', count(*) from {_ref(f'{tag}_b5')}
union all
select 'c', count(*) from {_ref(f'{tag}_c4')}"""))

    return nodes


def _dag_mesh15_mixed() -> list[tuple[str, str]]:
    """15 nodes: irregular mesh with cross-connections."""
    tag = "td_mesh15_mixed"
    return [
        # Sources (read ODS)
        (f"{tag}_s1", f"""
select customer_key, order_key, gross_item_sales_amount, order_date
from {_ref('orders_items')} where order_date > '1997-01-01'"""),
        (f"{tag}_s2", f"""
select customer_key, name, nation_key from {_ref('customers')}"""),
        (f"{tag}_s3", f"""
select order_key, customer_key, total_price from {_ref('orders')}"""),
        # Middle layer 1
        (f"{tag}_m1", f"""
select customer_key, sum(gross_item_sales_amount) as total
from {_ref(f'{tag}_s1')} group by 1"""),
        (f"{tag}_m2", _join_upstreams([f"{tag}_s1", f"{tag}_s2"])),
        (f"{tag}_m3", _join_upstreams([f"{tag}_s2", f"{tag}_s3"])),
        (f"{tag}_m4", f"""
select customer_key, count(*) as cnt from {_ref(f'{tag}_s3')} group by 1"""),
        (f"{tag}_m5", f"select * from {_ref(f'{tag}_s1')} where gross_item_sales_amount > 5000"),
        # Middle layer 2 (cross-connections)
        (f"{tag}_m6", _join_upstreams([f"{tag}_m1", f"{tag}_m2"])),
        (f"{tag}_m7", _join_upstreams([f"{tag}_m2", f"{tag}_m3"])),
        (f"{tag}_m8", _join_upstreams([f"{tag}_m4", f"{tag}_m3"])),
        (f"{tag}_m9", f"select * from {_ref(f'{tag}_m5')} limit 10000"),
        # Sinks
        (f"{tag}_t1", _union_upstreams([f"{tag}_m6", f"{tag}_m7"])),
        (f"{tag}_t2", _union_upstreams([f"{tag}_m7", f"{tag}_m8", f"{tag}_m9"])),
        (f"{tag}_t3", _light_count_upstream(f"{tag}_t1")),
    ]


# ---------------------------------------------------------------------------
# Programmatic 100-node DAG
# ---------------------------------------------------------------------------

# ODS tables and their characteristic queries for source nodes.
_ODS_SOURCES = [
    ("orders_items", "customer_key, order_key, gross_item_sales_amount, discount_percentage, order_date, ship_date"),
    ("orders", "order_key, customer_key, order_date, total_price, order_priority"),
    ("customers", "customer_key, name, nation_key, account_balance"),
    ("parts", "part_key, name as part_name, brand, type as part_type, size as part_size, retail_price"),
    ("suppliers", "supplier_key, name as supplier_name, nation_key as supp_nation_key"),
    ("parts_suppliers", "part_key, supplier_key, available_quantity, supply_cost"),
    ("nations", "nation_key, name as nation_name, region_key"),
    ("regions", "region_key, name as region_name"),
]


def _dag_layered100_slack() -> list[tuple[str, str]]:
    """100 nodes: 5-layer pipeline with deterministic wiring.

    Layer 0: 10 sources (heavy ODS scans)
    Layer 1: 25 transforms (medium: filter/agg upstream)
    Layer 2: 25 aggregators (medium-light: group by)
    Layer 3: 25 joiners (light: join small tables)
    Layer 4: 15 sinks (very light: count/limit)
    """
    tag = "td_layered100_slack"
    rng = random.Random(42)
    nodes: list[tuple[str, str]] = []

    # --- Layer 0: Sources (10 nodes) ---
    source_names = []
    for i in range(10):
        name = f"{tag}_s{i:02d}"
        source_names.append(name)
        ods_table, cols = _ODS_SOURCES[i % len(_ODS_SOURCES)]
        # Vary sources: some with window functions, some with filters
        if i < 4:
            # Heavy: window function
            first_col = cols.split(",")[0].strip()
            sql = f"""
select {cols},
       row_number() over (partition by {first_col} order by {first_col}) as rn
from {_ref(ods_table)}"""
        elif i < 7:
            # Medium-heavy: aggregation
            first_col = cols.split(",")[0].strip()
            sql = f"""
select {first_col}, count(*) as cnt
from {_ref(ods_table)}
group by 1"""
        else:
            # Medium: simple scan with filter
            sql = f"select {cols} from {_ref(ods_table)} limit 100000"
        nodes.append((name, sql))

    # --- Layer 1: Transforms (25 nodes) ---
    transform_names = []
    for i in range(25):
        name = f"{tag}_t{i:02d}"
        transform_names.append(name)
        # Each reads from 1-2 sources
        parent = rng.choice(source_names)
        if rng.random() < 0.3 and len(source_names) > 1:
            parent2 = rng.choice([s for s in source_names if s != parent])
            sql = f"""
select a.*, '{name}' as _node
from {_ref(parent)} a
join {_ref(parent2)} b on 1=1
limit 50000"""
        else:
            if i % 3 == 0:
                sql = f"select *, '{name}' as _node from {_ref(parent)} limit 50000"
            elif i % 3 == 1:
                sql = f"select count(*) as cnt, '{name}' as _node from {_ref(parent)}"
            else:
                sql = f"select *, '{name}' as _node from {_ref(parent)} where rn <= 1000"
        nodes.append((name, sql))

    # --- Layer 2: Aggregators (25 nodes) ---
    agg_names = []
    for i in range(25):
        name = f"{tag}_a{i:02d}"
        agg_names.append(name)
        parent = rng.choice(transform_names)
        sql = f"select count(*) as cnt, max(_node) as src, '{name}' as _node from {_ref(parent)}"
        nodes.append((name, sql))

    # --- Layer 3: Joiners (25 nodes) ---
    joiner_names = []
    for i in range(25):
        name = f"{tag}_j{i:02d}"
        joiner_names.append(name)
        # Each reads from 2-3 aggregators
        parents = rng.sample(agg_names, min(rng.randint(2, 3), len(agg_names)))
        base = parents[0]
        sql = f"select a.cnt as cnt_a, a.src, '{name}' as _node from {_ref(base)} a"
        for k, p in enumerate(parents[1:], 1):
            alias = chr(ord("a") + k)
            sql += f"\ncross join {_ref(p)} {alias}"
        nodes.append((name, sql))

    # --- Layer 4: Sinks (15 nodes) ---
    for i in range(15):
        name = f"{tag}_k{i:02d}"
        parent = rng.choice(joiner_names)
        sql = f"select count(*) as final_cnt, '{name}' as _node from {_ref(parent)}"
        nodes.append((name, sql))

    return nodes


# ---------------------------------------------------------------------------
# All DAGs
# ---------------------------------------------------------------------------

ALL_DAGS: dict[str, list[tuple[str, str]]] = {
    "td_solo_heavy": _dag_solo_heavy(),
    "td_solo_light": _dag_solo_light(),
    "td_chain3_slack": _dag_chain3_slack(),
    "td_fan3_mixed": _dag_fan3_mixed(),
    "td_chain10_slack": _dag_chain10_slack(),
    "td_diamond10_mixed": _dag_diamond10_mixed(),
    "td_wide10_slack": _dag_wide10_slack(),
    "td_tree10_mixed": _dag_tree10_mixed(),
    "td_pipeline15_slack": _dag_pipeline15_slack(),
    "td_mesh15_mixed": _dag_mesh15_mixed(),
    "td_layered100_slack": _dag_layered100_slack(),
}


# ---------------------------------------------------------------------------
# Mermaid diagram generation
# ---------------------------------------------------------------------------


def _generate_mermaid(all_dags: dict[str, list[tuple[str, str]]]) -> str:
    """Generate a mermaid diagram showing all test DAG topologies."""
    lines = ["# Test DAG Topologies", ""]

    for dag_name, models in sorted(all_dags.items()):
        lines.append(f"## {dag_name} ({len(models)} nodes)")
        lines.append("")
        lines.append("```mermaid")
        lines.append("graph LR")

        # Extract edges from ref() calls in SQL
        model_names = {m[0] for m in models}
        edge_lines = []
        for name, sql in models:
            # Find all ref() targets that are within this DAG
            import re
            refs = re.findall(r"\{\{\s*ref\(['\"](\w+)['\"]\)\s*\}\}", sql)
            for ref_target in refs:
                if ref_target in model_names:
                    # Shorten names for readability
                    short_src = ref_target.replace(f"{dag_name}_", "")
                    short_dst = name.replace(f"{dag_name}_", "")
                    edge_lines.append(f"    {short_src} --> {short_dst}")

        if edge_lines:
            lines.extend(sorted(set(edge_lines)))
        else:
            short = models[0][0].replace(f"{dag_name}_", "")
            lines.append(f"    {short}")

        lines.append("```")
        lines.append("")

    total = sum(len(m) for m in all_dags.values())
    lines.append(f"**{len(all_dags)} DAGs, {total} total models.**")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(description="Generate test DAGs for dag-downpacking pipeline")
    parser.add_argument("--clean", action="store_true", help="Remove existing td_* models first")
    args = parser.parse_args()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Clean existing td_* models
    if args.clean:
        removed = 0
        for f in os.listdir(OUTPUT_DIR):
            if f.startswith("td_") and f.endswith(".sql"):
                os.remove(os.path.join(OUTPUT_DIR, f))
                removed += 1
        if removed:
            print(f"Removed {removed} existing td_* models")

    # Remove any stale td_* models before writing
    for f in os.listdir(OUTPUT_DIR):
        if f.startswith("td_") and f.endswith(".sql"):
            os.remove(os.path.join(OUTPUT_DIR, f))

    # Write all models
    total = 0
    for dag_name, models in sorted(ALL_DAGS.items()):
        for model_name, sql_body in models:
            _write_model(model_name, sql_body, [dag_name])
            total += 1
        print(f"  {dag_name}: {len(models)} models")

    # Write mermaid diagram
    mermaid = _generate_mermaid(ALL_DAGS)
    mermaid_path = os.path.join(OUTPUT_DIR, "test_dags_DAG.md")
    with open(mermaid_path, "w") as f:
        f.write(mermaid)

    print(f"\nGenerated {total} models across {len(ALL_DAGS)} DAGs in {OUTPUT_DIR}")
    print(f"DAG diagram: {mermaid_path}")


if __name__ == "__main__":
    main()

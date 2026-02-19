"""Random DAG construction for generated dbt models.

Takes the flat list of generated models (all referencing ODS tables directly)
and rewires them into a realistic DAG by adding inter-model dependencies:

- Type A (source substitution): replace an ODS ref with a ref to an earlier
  model that passes through the same table's columns.
- Type B (existence dependency): prepend a no-op CTE that creates a scheduling
  edge without changing query output.

Acyclic by construction: edges only go from lower to higher positions in a
seeded random topological order.

Also handles:
- Converting ~100 table models to incremental materialization
- Generating a mermaid DAG diagram
"""

import os
import random
import re
import textwrap

# ODS tables that generated models reference
ODS_TABLES = [
    "orders_items", "orders", "customers", "parts",
    "suppliers", "parts_suppliers", "nations", "regions",
]


def _extract_refs(sql):
    """Extract all ref() targets from a model's SQL body."""
    return re.findall(r"\{\{\s*ref\(['\"](\w+)['\"]\)\s*\}\}", sql)


def _primary_ods_table(sql):
    """Return the first ODS table referenced, or None."""
    for ref in _extract_refs(sql):
        if ref in ODS_TABLES:
            return ref
    return None


def _has_order_date(sql):
    """Check if SQL references order_date (candidate for incremental)."""
    return "order_date" in sql.lower()


def build_dag(models, *, seed=42, p_source=0.25, p_dep=0.35):
    """Rewire models into a random DAG.

    Args:
        models: list of (name, sql, materialized, tags) tuples
        seed: random seed for reproducibility
        p_source: probability of Type A edge (source substitution)
        p_dep: probability of Type B edge (existence dependency)

    Returns:
        list of (name, sql, materialized, tags) tuples with DAG edges,
        dict mapping model_name -> list of upstream model names (for mermaid)
    """
    rng = random.Random(seed)

    # Build index for shuffling
    indexed = list(enumerate(models))
    rng.shuffle(indexed)

    # Track which models are "passthrough" for each ODS table.
    # A passthrough model selects all/most columns from a single ODS table
    # without aggregation — suitable as a Type A upstream.
    # We detect this from the tags: must have joins:0, agg:none, and scan a
    # single ODS table.
    def is_passthrough(tags, sql):
        has_join0 = "joins:0" in tags
        has_no_agg = "agg:none" in tags
        scan_tags = [t for t in tags if t.startswith("scan:")]
        if not scan_tags:
            return False
        scanned = scan_tags[0].replace("scan:", "")
        # Single table only (no + in scan tag)
        if "+" in scanned:
            return False
        # Must not have heavy filter or aggregation
        has_heavy = "filter:heavy" in tags
        return has_join0 and has_no_agg and not has_heavy and scanned in ODS_TABLES

    # Process models in topological order (shuffled order)
    result = [None] * len(models)
    edges = {}  # model_name -> [upstream_names]

    # For each ODS table, track passthrough models seen so far (by position)
    passthrough_by_table = {t: [] for t in ODS_TABLES}

    # All models seen so far (for Type B edges)
    seen = []

    for pos, (orig_idx, (name, sql, materialized, tags)) in enumerate(indexed):
        upstream = []

        if pos > 0:
            # --- Type A: source substitution ---
            if rng.random() < p_source:
                primary_table = _primary_ods_table(sql)
                if primary_table and passthrough_by_table[primary_table]:
                    # Pick a random passthrough model for this table
                    upstream_name = rng.choice(passthrough_by_table[primary_table])
                    # Replace the first ref to this ODS table with ref to upstream
                    old_ref = "{{ ref('" + primary_table + "') }}"
                    new_ref = "{{ ref('" + upstream_name + "') }}"
                    # Also handle the double-brace escaped version
                    old_ref_escaped = "{{ ref('" + primary_table + "') }}"
                    old_ref_fmt = "{{{{ ref('" + primary_table + "') }}}}"
                    new_ref_fmt = "{{{{ ref('" + upstream_name + "') }}}}"
                    # Replace first occurrence only (might ref same table multiple times)
                    if old_ref in sql:
                        sql = sql.replace(old_ref, new_ref, 1)
                        upstream.append(upstream_name)
                    elif old_ref_fmt in sql:
                        sql = sql.replace(old_ref_fmt, new_ref_fmt, 1)
                        upstream.append(upstream_name)

            # --- Type B: existence dependency ---
            if rng.random() < p_dep and seen:
                dep_name = rng.choice(seen)
                dep_cte = f"_dep as (select 1 from {{{{ ref('{dep_name}') }}}} limit 1)"
                # Prepend the CTE. If SQL already has a 'with' clause, add as
                # first CTE; otherwise add 'with ... ,'
                stripped = sql.lstrip()
                if stripped.lower().startswith("with "):
                    # Insert after 'with '
                    idx = sql.lower().index("with ") + 5
                    sql = sql[:idx] + dep_cte + ",\n" + sql[idx:]
                else:
                    sql = "\nwith " + dep_cte + "\n" + sql
                upstream.append(dep_name)

        # Track passthrough
        if is_passthrough(tags, sql):
            table = _primary_ods_table(sql)
            if table:
                passthrough_by_table[table].append(name)

        seen.append(name)
        edges[name] = upstream
        result[orig_idx] = (name, sql, materialized, tags)

    return result, edges


def convert_to_incremental(models, *, seed=42, target_count=100):
    """Convert ~target_count table models with order_date to incremental.

    Args:
        models: list of (name, sql, materialized, tags)
        seed: random seed
        target_count: approximate number of models to convert

    Returns:
        list of (name, sql, materialized, tags) with some converted
    """
    rng = random.Random(seed + 1)  # different seed to decouple from DAG

    # Find eligible models: table materialization with order_date in SQL
    eligible = []
    for i, (name, sql, materialized, tags) in enumerate(models):
        if materialized == "table" and _has_order_date(sql):
            eligible.append(i)

    # Sample target_count from eligible
    count = min(target_count, len(eligible))
    selected = set(rng.sample(eligible, count))

    result = []
    for i, (name, sql, materialized, tags) in enumerate(models):
        if i in selected:
            # Add incremental filter before the final semicolon / end of SQL
            inc_block = "\n{% if is_incremental() %}\n  where order_date > (select max(order_date) from {{ this }})\n{% endif %}"

            # Insert the incremental block. If SQL has a WHERE clause at the
            # outermost level, we need to handle it differently.
            # Strategy: append the block after the main query body but before
            # any trailing whitespace/comments.
            stripped = sql.rstrip()

            # Check if the query ends with GROUP BY or ORDER BY — need to
            # insert before those. For simplicity, just append as an AND clause
            # is tricky. Instead use a wrapping approach: the incremental
            # filter goes after the entire query.
            #
            # Actually, for dbt incremental models, the standard pattern is:
            # {% if is_incremental() %} where ... {% endif %}
            # appended at the end of the query. If there's already a WHERE,
            # dbt users typically use AND. Let's check.
            if "where " in stripped.lower() and "group by" not in stripped.lower():
                # Has WHERE but no GROUP BY — add AND
                inc_block = "\n{% if is_incremental() %}\n  and order_date > (select max(order_date) from {{ this }})\n{% endif %}"
                sql = stripped + inc_block + "\n"
            elif "group by" in stripped.lower():
                # Has GROUP BY — need to insert before it
                # Find the last 'group by' and insert before it
                gb_pos = stripped.lower().rfind("group by")
                inc_where = "\n{% if is_incremental() %}\n  where order_date > (select max(order_date) from {{ this }})\n{% endif %}\n"
                if "where " in stripped[:gb_pos].lower():
                    inc_where = "\n{% if is_incremental() %}\n  and order_date > (select max(order_date) from {{ this }})\n{% endif %}\n"
                sql = stripped[:gb_pos] + inc_where + stripped[gb_pos:] + "\n"
            else:
                # No WHERE, no GROUP BY — simple append
                sql = stripped + inc_block + "\n"

            result.append((name, sql, "incremental", tags))
        else:
            result.append((name, sql, materialized, tags))

    return result


def generate_mermaid(edges, output_path):
    """Generate a mermaid DAG diagram from the edges dict.

    Args:
        edges: dict mapping model_name -> [upstream_model_names]
        output_path: path to write the .md file
    """
    lines = ["# Generated Model DAG", "", "```mermaid", "graph LR"]

    # Collect all nodes that have edges
    nodes_with_edges = set()
    edge_lines = []
    for model, upstreams in sorted(edges.items()):
        for up in upstreams:
            edge_lines.append(f"    {up} --> {model}")
            nodes_with_edges.add(model)
            nodes_with_edges.add(up)

    # Only include models that participate in edges (otherwise diagram is huge)
    if edge_lines:
        lines.extend(sorted(edge_lines))
    else:
        lines.append("    no_edges[No DAG edges]")

    lines.append("```")
    lines.append("")
    lines.append(f"**{len(nodes_with_edges)}** models with DAG edges, "
                 f"**{len(edge_lines)}** edges total.")
    lines.append("")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write("\n".join(lines))

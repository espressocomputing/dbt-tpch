#!/usr/bin/env python3
"""Generate ~1000 dbt models with varied query characteristics for proxy benchmarking.

Usage:
    python tools/generate_models.py              # with DAG (default)
    python tools/generate_models.py --no-dag     # flat fan-out (no DAG)
    python tools/generate_models.py --seed 123   # custom seed

Idempotent: deletes models/generated/ and recreates from scratch.
Generated models reference ODS tables (and each other when DAG is enabled).

Each model is tagged with technical properties describing its query shape:
  - scan:<table> — which ODS table(s) are scanned
  - joins:<n> — number of joins in the query
  - agg:<type> — none, simple (GROUP BY), window, or multi (both)
  - rows_sf1:<n> — estimated output row count at SF1
  - cols:<n> — number of output columns
  - filter:<type> — none, light (<50% selectivity), heavy (>90% reduction)
"""

import argparse
import os
import shutil
import textwrap

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "models", "generated")

# TPC-H row counts at SF1 (multiply by SF for other scale factors)
# These are approximate and used for tagging only
ROW_COUNTS_SF1 = {
    "orders_items": 6_001_215,
    "orders": 1_500_000,
    "customers": 150_000,
    "parts": 200_000,
    "suppliers": 10_000,
    "parts_suppliers": 800_000,
    "nations": 25,
    "regions": 5,
}

models = []


def add(name, sql, *, materialized="view", tags=None):
    """Register a model to be written."""
    models.append((name, sql, materialized, tags or []))


def config_block(materialized, tags):
    tag_str = ", ".join(f"'{t}'" for t in ["generated"] + tags)
    # Include sf tag dynamically so SF1 and SF10 runs are distinguishable
    return textwrap.dedent(f"""\
        {{{{
            config(
                materialized = '{materialized}',
                tags = [{tag_str}, 'sf' ~ var('sf', '10')]
            )
        }}}}""")


def model_sql(body, materialized, tags):
    return config_block(materialized, tags) + "\n" + body


# ---------------------------------------------------------------------------
# TEMPLATE FAMILIES
# Each family generates multiple variants by varying filters, columns, etc.
# ---------------------------------------------------------------------------


# === FAMILY 1: Single-table scans on orders_items (the biggest table) ===
# ~60M rows at SF10. Good for testing scan-heavy queries.

# 1a. Full scan, all columns (wide)
add("oi_full_scan", """
select
    order_item_key, order_key, order_date, customer_key, order_status_code,
    part_key, supplier_key, return_status_code, order_line_number,
    order_line_status_code, ship_date, commit_date, receipt_date,
    ship_mode_name, quantity, base_price, discount_percentage,
    discounted_price, gross_item_sales_amount, discounted_item_sales_amount,
    item_discount_amount, tax_rate, item_tax_amount, net_item_sales_amount
from {{ ref('orders_items') }}
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:none",
    "rows_sf1:6M", "cols:24", "filter:none",
])

# 1b. Filtered scans with different selectivities
for i, (label, predicate, est_rows, ftype) in enumerate([
    ("recent_90d", "ship_date >= dateadd(day, -90, '1998-12-01')", "1.5M", "light"),
    ("recent_30d", "ship_date >= dateadd(day, -30, '1998-12-01')", "500K", "medium"),
    ("high_value", "gross_item_sales_amount > 50000", "600K", "light"),
    ("high_discount", "discount_percentage > 0.08", "600K", "light"),
    ("returned", "return_status_code = 'R'", "1.5M", "light"),
    ("air_ship", "ship_mode_name = 'AIR'", "860K", "light"),
    ("rail_ship", "ship_mode_name = 'RAIL'", "860K", "light"),
    ("truck_ship", "ship_mode_name = 'TRUCK'", "860K", "light"),
    ("urgent_returned", "return_status_code = 'R' and order_status_code = 'F'", "750K", "heavy"),
    ("tiny_orders", "quantity = 1 and discount_percentage = 0", "30K", "heavy"),
]):
    add(f"oi_filter_{label}", f"""
select
    order_item_key, order_key, order_date, customer_key,
    part_key, supplier_key, quantity, base_price,
    gross_item_sales_amount, net_item_sales_amount
from {{{{ ref('orders_items') }}}}
where {predicate}
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:none",
    f"rows_sf1:{est_rows}", "cols:10", f"filter:{ftype}",
])

# 1c. Aggregations on orders_items
agg_variants = [
    ("oi_agg_by_status", "order_status_code",
     "count(*) as cnt, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales",
     "5", "simple"),
    ("oi_agg_by_ship_mode", "ship_mode_name",
     "count(*) as cnt, sum(quantity) as total_qty, avg(base_price) as avg_price, sum(net_item_sales_amount) as total_net",
     "7", "simple"),
    ("oi_agg_by_return", "return_status_code",
     "count(*) as cnt, sum(gross_item_sales_amount) as total_gross, sum(item_discount_amount) as total_discount",
     "3", "simple"),
    ("oi_agg_by_month", "date_trunc('month', order_date)",
     "count(*) as cnt, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales, avg(discount_percentage) as avg_discount",
     "84", "simple"),
    ("oi_agg_by_year", "date_trunc('year', order_date)",
     "count(*) as cnt, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales",
     "7", "simple"),
    ("oi_agg_by_quarter", "date_trunc('quarter', order_date)",
     "count(*) as cnt, sum(gross_item_sales_amount) as total_sales, sum(net_item_sales_amount) as total_net",
     "28", "simple"),
    ("oi_agg_by_customer", "customer_key",
     "count(*) as order_item_count, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales, min(order_date) as first_order, max(order_date) as last_order",
     "150K", "simple"),
    ("oi_agg_by_part", "part_key",
     "count(*) as times_ordered, sum(quantity) as total_qty, avg(base_price) as avg_price",
     "200K", "simple"),
    ("oi_agg_by_supplier", "supplier_key",
     "count(*) as items_supplied, sum(gross_item_sales_amount) as total_sales, avg(discount_percentage) as avg_discount",
     "10K", "simple"),
    ("oi_agg_by_date", "order_date",
     "count(*) as cnt, sum(gross_item_sales_amount) as total_sales",
     "2500", "simple"),
]

for name, group_col, agg_expr, est_rows, agg_type in agg_variants:
    add(name, f"""
select
    {group_col} as group_key,
    {agg_expr}
from {{{{ ref('orders_items') }}}}
group by 1
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", f"agg:{agg_type}",
    f"rows_sf1:{est_rows}", "cols:4", "filter:none",
])

# 1d. Window functions on orders_items
window_variants = [
    ("oi_win_rank_by_customer", """
select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    row_number() over (partition by customer_key order by gross_item_sales_amount desc) as sales_rank,
    sum(gross_item_sales_amount) over (partition by customer_key) as customer_total
from {{ ref('orders_items') }}
""", "6M", "24"),
    ("oi_win_running_total", """
select
    order_item_key, order_date, gross_item_sales_amount,
    sum(gross_item_sales_amount) over (order by order_date rows unbounded preceding) as running_total,
    avg(gross_item_sales_amount) over (order by order_date rows between 99 preceding and current row) as moving_avg_100
from {{ ref('orders_items') }}
""", "6M", "5"),
    ("oi_win_lag_lead", """
select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    lag(gross_item_sales_amount) over (partition by customer_key order by order_date) as prev_sales,
    lead(gross_item_sales_amount) over (partition by customer_key order by order_date) as next_sales
from {{ ref('orders_items') }}
""", "6M", "6"),
    ("oi_win_ntile", """
select
    order_item_key, customer_key, gross_item_sales_amount,
    ntile(100) over (order by gross_item_sales_amount) as percentile_bucket,
    ntile(10) over (partition by customer_key order by gross_item_sales_amount) as decile_bucket
from {{ ref('orders_items') }}
""", "6M", "5"),
    ("oi_win_dense_rank_part", """
select
    order_item_key, part_key, supplier_key, quantity,
    dense_rank() over (partition by part_key order by quantity desc) as qty_rank,
    percent_rank() over (partition by part_key order by gross_item_sales_amount) as pct_rank
from {{ ref('orders_items') }}
""", "6M", "6"),
]

for name, body, est_rows, cols in window_variants:
    add(name, body, materialized="view", tags=[
        "scan:orders_items", "joins:0", "agg:window",
        f"rows_sf1:{est_rows}", f"cols:{cols}", "filter:none",
    ])

# 1e. Window + filter combos
for filt_label, predicate in [
    ("recent", "ship_date >= dateadd(day, -180, '1998-12-01')"),
    ("returned", "return_status_code = 'R'"),
    ("air", "ship_mode_name = 'AIR'"),
]:
    add(f"oi_win_rank_{filt_label}", f"""
select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    row_number() over (partition by customer_key order by gross_item_sales_amount desc) as sales_rank
from {{{{ ref('orders_items') }}}}
where {predicate}
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:window",
    "rows_sf1:1.5M", "cols:5", "filter:light",
])

# 1f. Agg + filter combos
for filt_label, predicate in [
    ("recent_90d", "ship_date >= dateadd(day, -90, '1998-12-01')"),
    ("returned", "return_status_code = 'R'"),
    ("high_value", "gross_item_sales_amount > 50000"),
    ("air", "ship_mode_name = 'AIR'"),
]:
    add(f"oi_agg_filtered_{filt_label}", f"""
select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {{{{ ref('orders_items') }}}}
where {predicate}
group by 1
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:simple",
    "rows_sf1:84", "cols:4", "filter:light",
])


# === FAMILY 2: Single-table scans on orders (1.5M at SF1) ===

add("ord_full_scan", """
select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_clerk_name, shipping_priority, order_amount
from {{ ref('orders') }}
""", materialized="view", tags=[
    "scan:orders", "joins:0", "agg:none",
    "rows_sf1:1.5M", "cols:8", "filter:none",
])

for i, (label, predicate, est_rows, ftype) in enumerate([
    ("fulfilled", "order_status_code = 'F'", "750K", "light"),
    ("open", "order_status_code = 'O'", "750K", "light"),
    ("high_priority", "order_priority_code in ('1-URGENT', '2-HIGH')", "600K", "light"),
    ("low_priority", "order_priority_code = '5-LOW'", "300K", "light"),
    ("big_orders", "order_amount > 400000", "30K", "heavy"),
    ("recent_year", "order_date >= '1997-01-01'", "220K", "light"),
    ("old_orders", "order_date < '1993-01-01'", "200K", "heavy"),
]):
    add(f"ord_filter_{label}", f"""
select
    order_key, order_date, customer_key, order_status_code,
    order_priority_code, order_amount
from {{{{ ref('orders') }}}}
where {predicate}
""", materialized="view", tags=[
    "scan:orders", "joins:0", "agg:none",
    f"rows_sf1:{est_rows}", "cols:6", f"filter:{ftype}",
])

ord_agg_variants = [
    ("ord_agg_by_status", "order_status_code",
     "count(*) as cnt, sum(order_amount) as total_amount, avg(order_amount) as avg_amount", "3"),
    ("ord_agg_by_priority", "order_priority_code",
     "count(*) as cnt, sum(order_amount) as total_amount", "5"),
    ("ord_agg_by_month", "date_trunc('month', order_date)",
     "count(*) as cnt, sum(order_amount) as total_amount, avg(order_amount) as avg_amount", "84"),
    ("ord_agg_by_year", "date_trunc('year', order_date)",
     "count(*) as cnt, sum(order_amount) as total_amount", "7"),
    ("ord_agg_by_customer", "customer_key",
     "count(*) as order_count, sum(order_amount) as total_spent, min(order_date) as first_order, max(order_date) as last_order", "150K"),
    ("ord_agg_by_clerk", "order_clerk_name",
     "count(*) as cnt, sum(order_amount) as total_amount", "1000"),
    ("ord_agg_by_date_status", "order_date, order_status_code",
     "count(*) as cnt, sum(order_amount) as total_amount", "5K"),
]

def _is_multi_col(group_col):
    """Check if group_col has multiple columns (comma outside parentheses)."""
    depth = 0
    for c in group_col:
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
        elif c == ',' and depth == 0:
            return True
    return False

for name, group_col, agg_expr, est_rows in ord_agg_variants:
    add(name, f"""
select
    {group_col},
    {agg_expr}
from {{{{ ref('orders') }}}}
group by 1, 2
""" if _is_multi_col(group_col) else f"""
select
    {group_col} as group_key,
    {agg_expr}
from {{{{ ref('orders') }}}}
group by 1
""", materialized="view", tags=[
    "scan:orders", "joins:0", "agg:simple",
    f"rows_sf1:{est_rows}", "cols:4", "filter:none",
])

# Window functions on orders
for name, body, est_rows in [
    ("ord_win_customer_rank", """
select
    order_key, customer_key, order_date, order_amount,
    row_number() over (partition by customer_key order by order_date) as order_seq,
    sum(order_amount) over (partition by customer_key order by order_date rows unbounded preceding) as cumulative_spend
from {{ ref('orders') }}
""", "1.5M"),
    ("ord_win_running_avg", """
select
    order_key, order_date, order_amount,
    avg(order_amount) over (order by order_date rows between 999 preceding and current row) as moving_avg_1000,
    count(*) over (order by order_date rows between 999 preceding and current row) as window_size
from {{ ref('orders') }}
""", "1.5M"),
]:
    add(name, body, materialized="view", tags=[
        "scan:orders", "joins:0", "agg:window",
        f"rows_sf1:{est_rows}", "cols:6", "filter:none",
    ])


# === FAMILY 3: Single-table scans on customers (150K at SF1) ===

add("cust_full_scan", """
select
    customer_key, customer_name, customer_address, nation_key,
    customer_phone_number, customer_account_balance, customer_market_segment_name
from {{ ref('customers') }}
""", materialized="view", tags=[
    "scan:customers", "joins:0", "agg:none",
    "rows_sf1:150K", "cols:7", "filter:none",
])

for label, predicate, est_rows in [
    ("auto", "customer_market_segment_name = 'AUTOMOBILE'", "30K"),
    ("building", "customer_market_segment_name = 'BUILDING'", "30K"),
    ("high_balance", "customer_account_balance > 9000", "15K"),
    ("negative_balance", "customer_account_balance < 0", "7K"),
]:
    add(f"cust_filter_{label}", f"""
select
    customer_key, customer_name, nation_key,
    customer_account_balance, customer_market_segment_name
from {{{{ ref('customers') }}}}
where {predicate}
""", materialized="view", tags=[
    "scan:customers", "joins:0", "agg:none",
    f"rows_sf1:{est_rows}", "cols:5", "filter:light",
])

cust_aggs = [
    ("cust_agg_by_segment", "customer_market_segment_name",
     "count(*) as cnt, avg(customer_account_balance) as avg_balance, sum(customer_account_balance) as total_balance", "5"),
    ("cust_agg_by_nation", "nation_key",
     "count(*) as cnt, avg(customer_account_balance) as avg_balance", "25"),
    ("cust_agg_balance_bucket", "floor(customer_account_balance / 1000) * 1000",
     "count(*) as cnt", "20"),
]

for name, group_col, agg_expr, est_rows in cust_aggs:
    add(name, f"""
select
    {group_col} as group_key,
    {agg_expr}
from {{{{ ref('customers') }}}}
group by 1
""", materialized="view", tags=[
    "scan:customers", "joins:0", "agg:simple",
    f"rows_sf1:{est_rows}", "cols:3", "filter:none",
])


# === FAMILY 4: Single-table scans on parts (200K at SF1) ===

add("parts_full_scan", """
select
    part_key, part_name, part_manufacturer_name, part_brand_name,
    part_type_name, part_size, part_container_desc, retail_price
from {{ ref('parts') }}
""", materialized="view", tags=[
    "scan:parts", "joins:0", "agg:none",
    "rows_sf1:200K", "cols:8", "filter:none",
])

for label, predicate, est_rows in [
    ("brand_11", "part_brand_name = 'Brand#11'", "4K"),
    ("small", "part_size <= 5", "20K"),
    ("large", "part_size >= 45", "20K"),
    ("expensive", "retail_price > 1900", "20K"),
    ("economy", "part_type_name like '%ECONOMY%'", "25K"),
    ("brass", "part_type_name like '%BRASS%'", "25K"),
]:
    add(f"parts_filter_{label}", f"""
select
    part_key, part_name, part_brand_name, part_type_name, part_size, retail_price
from {{{{ ref('parts') }}}}
where {predicate}
""", materialized="view", tags=[
    "scan:parts", "joins:0", "agg:none",
    f"rows_sf1:{est_rows}", "cols:6", "filter:light",
])

parts_aggs = [
    ("parts_agg_by_brand", "part_brand_name",
     "count(*) as cnt, avg(retail_price) as avg_price, min(part_size) as min_size, max(part_size) as max_size", "25"),
    ("parts_agg_by_mfgr", "part_manufacturer_name",
     "count(*) as cnt, avg(retail_price) as avg_price", "5"),
    ("parts_agg_by_type", "part_type_name",
     "count(*) as cnt, avg(retail_price) as avg_price", "150"),
    ("parts_agg_by_container", "part_container_desc",
     "count(*) as cnt, avg(retail_price) as avg_price", "40"),
    ("parts_agg_by_size", "part_size",
     "count(*) as cnt, avg(retail_price) as avg_price", "50"),
]

for name, group_col, agg_expr, est_rows in parts_aggs:
    add(name, f"""
select
    {group_col} as group_key,
    {agg_expr}
from {{{{ ref('parts') }}}}
group by 1
""", materialized="view", tags=[
    "scan:parts", "joins:0", "agg:simple",
    f"rows_sf1:{est_rows}", "cols:4", "filter:none",
])


# === FAMILY 5: Single-table scans on suppliers (10K at SF1) ===

add("supp_full_scan", """
select
    supplier_key, supplier_name, supplier_address, nation_key,
    supplier_phone_number, supplier_account_balance
from {{ ref('suppliers') }}
""", materialized="view", tags=[
    "scan:suppliers", "joins:0", "agg:none",
    "rows_sf1:10K", "cols:6", "filter:none",
])

supp_aggs = [
    ("supp_agg_by_nation", "nation_key",
     "count(*) as cnt, avg(supplier_account_balance) as avg_balance", "25"),
]

for name, group_col, agg_expr, est_rows in supp_aggs:
    add(name, f"""
select
    {group_col} as group_key,
    {agg_expr}
from {{{{ ref('suppliers') }}}}
group by 1
""", materialized="view", tags=[
    "scan:suppliers", "joins:0", "agg:simple",
    f"rows_sf1:{est_rows}", "cols:3", "filter:none",
])


# === FAMILY 6: Single-table on parts_suppliers (800K at SF1) ===

add("ps_full_scan", """
select
    part_supplier_key, part_key, part_name, part_brand_name,
    supplier_key, supplier_name, nation_key,
    supplier_availabe_quantity, supplier_cost_amount
from {{ ref('parts_suppliers') }}
""", materialized="view", tags=[
    "scan:parts_suppliers", "joins:0", "agg:none",
    "rows_sf1:800K", "cols:9", "filter:none",
])

ps_aggs = [
    ("ps_agg_by_part", "part_key",
     "count(*) as supplier_count, avg(supplier_cost_amount) as avg_cost, sum(supplier_availabe_quantity) as total_avail", "200K"),
    ("ps_agg_by_supplier", "supplier_key",
     "count(*) as part_count, avg(supplier_cost_amount) as avg_cost, sum(supplier_availabe_quantity) as total_avail", "10K"),
    ("ps_agg_by_nation", "nation_key",
     "count(*) as cnt, avg(supplier_cost_amount) as avg_cost", "25"),
]

for name, group_col, agg_expr, est_rows in ps_aggs:
    add(name, f"""
select
    {group_col} as group_key,
    {agg_expr}
from {{{{ ref('parts_suppliers') }}}}
group by 1
""", materialized="view", tags=[
    "scan:parts_suppliers", "joins:0", "agg:simple",
    f"rows_sf1:{est_rows}", "cols:4", "filter:none",
])


# === FAMILY 7: Two-table joins ===

# orders + customers (1.5M x 150K → 1.5M rows)
join2_variants = [
    ("join_orders_customers", """
select
    o.order_key, o.order_date, o.order_amount, o.order_status_code,
    c.customer_name, c.customer_market_segment_name, c.customer_account_balance
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
""", "scan:orders+customers", "1.5M", "7", "none"),
    ("join_orders_customers_auto", """
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_account_balance
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where c.customer_market_segment_name = 'AUTOMOBILE'
""", "scan:orders+customers", "300K", "5", "light"),
    ("join_orders_customers_building", """
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_account_balance
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where c.customer_market_segment_name = 'BUILDING'
""", "scan:orders+customers", "300K", "5", "light"),
    ("join_orders_customers_high_bal", """
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_account_balance
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where c.customer_account_balance > 9000
""", "scan:orders+customers", "150K", "5", "heavy"),
]

for name, body, scan, est_rows, cols, ftype in join2_variants:
    add(name, body, materialized="view", tags=[
        scan, "joins:1", "agg:none",
        f"rows_sf1:{est_rows}", f"cols:{cols}", f"filter:{ftype}",
    ])

# orders + customers with aggregation
join2_agg_variants = [
    ("join_ord_cust_agg_segment", """
select
    c.customer_market_segment_name,
    count(*) as order_count,
    sum(o.order_amount) as total_amount,
    avg(o.order_amount) as avg_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
group by 1
""", "scan:orders+customers", "5", "4"),
    ("join_ord_cust_agg_nation", """
select
    c.nation_key,
    count(*) as order_count,
    sum(o.order_amount) as total_amount,
    avg(o.order_amount) as avg_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
group by 1
""", "scan:orders+customers", "25", "4"),
    ("join_ord_cust_agg_month_seg", """
select
    date_trunc('month', o.order_date) as month,
    c.customer_market_segment_name,
    count(*) as order_count,
    sum(o.order_amount) as total_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
group by 1, 2
""", "scan:orders+customers", "420", "4"),
]

for name, body, scan, est_rows, cols in join2_agg_variants:
    add(name, body, materialized="view", tags=[
        scan, "joins:1", "agg:simple",
        f"rows_sf1:{est_rows}", f"cols:{cols}", "filter:none",
    ])

# orders_items + customers
add("join_oi_customers", """
select
    oi.order_item_key, oi.order_date, oi.part_key, oi.supplier_key,
    oi.quantity, oi.gross_item_sales_amount,
    c.customer_name, c.customer_market_segment_name
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
""", materialized="view", tags=[
    "scan:orders_items+customers", "joins:1", "agg:none",
    "rows_sf1:6M", "cols:8", "filter:none",
])

add("join_oi_cust_agg_seg_month", """
select
    c.customer_market_segment_name,
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    sum(oi.item_discount_amount) as total_discount
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
group by 1, 2
""", materialized="view", tags=[
    "scan:orders_items+customers", "joins:1", "agg:simple",
    "rows_sf1:420", "cols:5", "filter:none",
])

# orders_items + parts
add("join_oi_parts", """
select
    oi.order_item_key, oi.order_date, oi.customer_key, oi.supplier_key,
    oi.quantity, oi.gross_item_sales_amount,
    p.part_name, p.part_brand_name, p.part_type_name, p.retail_price
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
""", materialized="view", tags=[
    "scan:orders_items+parts", "joins:1", "agg:none",
    "rows_sf1:6M", "cols:10", "filter:none",
])

add("join_oi_parts_brass", """
select
    oi.order_item_key, oi.order_date, oi.quantity, oi.gross_item_sales_amount,
    p.part_name, p.part_type_name, p.retail_price
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
where p.part_type_name like '%BRASS%'
""", materialized="view", tags=[
    "scan:orders_items+parts", "joins:1", "agg:none",
    "rows_sf1:750K", "cols:7", "filter:light",
])

add("join_oi_parts_agg_brand", """
select
    p.part_brand_name,
    count(*) as item_count,
    sum(oi.quantity) as total_qty,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
group by 1
""", materialized="view", tags=[
    "scan:orders_items+parts", "joins:1", "agg:simple",
    "rows_sf1:25", "cols:5", "filter:none",
])

add("join_oi_parts_agg_type", """
select
    p.part_type_name,
    count(*) as item_count,
    sum(oi.quantity) as total_qty,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
group by 1
""", materialized="view", tags=[
    "scan:orders_items+parts", "joins:1", "agg:simple",
    "rows_sf1:150", "cols:4", "filter:none",
])

# orders_items + suppliers
add("join_oi_suppliers", """
select
    oi.order_item_key, oi.order_date, oi.customer_key, oi.part_key,
    oi.quantity, oi.gross_item_sales_amount,
    s.supplier_name, s.nation_key, s.supplier_account_balance
from {{ ref('orders_items') }} oi
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
""", materialized="view", tags=[
    "scan:orders_items+suppliers", "joins:1", "agg:none",
    "rows_sf1:6M", "cols:9", "filter:none",
])

add("join_oi_supp_agg_nation", """
select
    s.nation_key,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
group by 1
""", materialized="view", tags=[
    "scan:orders_items+suppliers", "joins:1", "agg:simple",
    "rows_sf1:25", "cols:4", "filter:none",
])

# parts_suppliers + nations
add("join_ps_nations", """
select
    ps.part_supplier_key, ps.part_key, ps.supplier_key,
    ps.supplier_cost_amount, ps.supplier_availabe_quantity,
    n.nation_name
from {{ ref('parts_suppliers') }} ps
join {{ ref('nations') }} n on ps.nation_key = n.nation_key
""", materialized="view", tags=[
    "scan:parts_suppliers+nations", "joins:1", "agg:none",
    "rows_sf1:800K", "cols:6", "filter:none",
])

# customers + nations
add("join_cust_nations", """
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    c.customer_account_balance,
    n.nation_name
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
""", materialized="view", tags=[
    "scan:customers+nations", "joins:1", "agg:none",
    "rows_sf1:150K", "cols:5", "filter:none",
])

add("join_cust_nations_agg", """
select
    n.nation_name,
    count(*) as customer_count,
    avg(c.customer_account_balance) as avg_balance,
    sum(c.customer_account_balance) as total_balance
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1
""", materialized="view", tags=[
    "scan:customers+nations", "joins:1", "agg:simple",
    "rows_sf1:25", "cols:4", "filter:none",
])

# suppliers + nations
add("join_supp_nations", """
select
    s.supplier_key, s.supplier_name, s.supplier_account_balance,
    n.nation_name
from {{ ref('suppliers') }} s
join {{ ref('nations') }} n on s.nation_key = n.nation_key
""", materialized="view", tags=[
    "scan:suppliers+nations", "joins:1", "agg:none",
    "rows_sf1:10K", "cols:4", "filter:none",
])


# === FAMILY 8: Three-table joins ===

# orders + customers + nations
add("join3_ord_cust_nat", """
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_market_segment_name,
    n.nation_name
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
""", materialized="view", tags=[
    "scan:orders+customers+nations", "joins:2", "agg:none",
    "rows_sf1:1.5M", "cols:6", "filter:none",
])

add("join3_ord_cust_nat_agg_nation", """
select
    n.nation_name,
    count(*) as order_count,
    sum(o.order_amount) as total_amount,
    avg(o.order_amount) as avg_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1
""", materialized="view", tags=[
    "scan:orders+customers+nations", "joins:2", "agg:simple",
    "rows_sf1:25", "cols:4", "filter:none",
])

add("join3_ord_cust_nat_agg_month_nation", """
select
    n.nation_name,
    date_trunc('month', o.order_date) as month,
    count(*) as order_count,
    sum(o.order_amount) as total_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1, 2
""", materialized="view", tags=[
    "scan:orders+customers+nations", "joins:2", "agg:simple",
    "rows_sf1:2100", "cols:4", "filter:none",
])

# orders_items + customers + nations
add("join3_oi_cust_nat", """
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount,
    c.customer_market_segment_name,
    n.nation_name
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
""", materialized="view", tags=[
    "scan:orders_items+customers+nations", "joins:2", "agg:none",
    "rows_sf1:6M", "cols:6", "filter:none",
])

add("join3_oi_cust_nat_agg", """
select
    n.nation_name,
    c.customer_market_segment_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1, 2
""", materialized="view", tags=[
    "scan:orders_items+customers+nations", "joins:2", "agg:simple",
    "rows_sf1:125", "cols:5", "filter:none",
])

# orders_items + parts + suppliers
add("join3_oi_parts_supp", """
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount, oi.discount_percentage,
    p.part_name, p.part_brand_name, p.part_type_name,
    s.supplier_name, s.nation_key
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
""", materialized="view", tags=[
    "scan:orders_items+parts+suppliers", "joins:2", "agg:none",
    "rows_sf1:6M", "cols:10", "filter:none",
])

add("join3_oi_parts_supp_agg_brand", """
select
    p.part_brand_name,
    s.nation_key,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    sum(oi.quantity) as total_qty
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
group by 1, 2
""", materialized="view", tags=[
    "scan:orders_items+parts+suppliers", "joins:2", "agg:simple",
    "rows_sf1:625", "cols:5", "filter:none",
])

# parts_suppliers + nations + regions
add("join3_ps_nat_reg", """
select
    ps.part_supplier_key, ps.part_key, ps.supplier_key,
    ps.supplier_cost_amount,
    n.nation_name,
    r.region_name
from {{ ref('parts_suppliers') }} ps
join {{ ref('nations') }} n on ps.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
""", materialized="view", tags=[
    "scan:parts_suppliers+nations+regions", "joins:2", "agg:none",
    "rows_sf1:800K", "cols:6", "filter:none",
])

add("join3_ps_nat_reg_agg_region", """
select
    r.region_name,
    count(*) as ps_count,
    avg(ps.supplier_cost_amount) as avg_cost,
    sum(ps.supplier_availabe_quantity) as total_avail
from {{ ref('parts_suppliers') }} ps
join {{ ref('nations') }} n on ps.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1
""", materialized="view", tags=[
    "scan:parts_suppliers+nations+regions", "joins:2", "agg:simple",
    "rows_sf1:5", "cols:4", "filter:none",
])

# customers + nations + regions
add("join3_cust_nat_reg", """
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    c.customer_account_balance,
    n.nation_name,
    r.region_name
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
""", materialized="view", tags=[
    "scan:customers+nations+regions", "joins:2", "agg:none",
    "rows_sf1:150K", "cols:6", "filter:none",
])

add("join3_cust_nat_reg_agg_region", """
select
    r.region_name,
    count(*) as customer_count,
    avg(c.customer_account_balance) as avg_balance,
    sum(c.customer_account_balance) as total_balance
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1
""", materialized="view", tags=[
    "scan:customers+nations+regions", "joins:2", "agg:simple",
    "rows_sf1:5", "cols:4", "filter:none",
])

# suppliers + nations + regions
add("join3_supp_nat_reg", """
select
    s.supplier_key, s.supplier_name, s.supplier_account_balance,
    n.nation_name, r.region_name
from {{ ref('suppliers') }} s
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
""", materialized="view", tags=[
    "scan:suppliers+nations+regions", "joins:2", "agg:none",
    "rows_sf1:10K", "cols:5", "filter:none",
])


# === FAMILY 9: Four+ table joins (complex) ===

# orders + orders_items + customers + nations
add("join4_oi_cust_nat_reg", """
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount, oi.ship_mode_name,
    c.customer_name, c.customer_market_segment_name,
    n.nation_name, r.region_name
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
""", materialized="view", tags=[
    "scan:orders_items+customers+nations+regions", "joins:3", "agg:none",
    "rows_sf1:6M", "cols:9", "filter:none",
])

add("join4_oi_cust_nat_reg_agg", """
select
    r.region_name,
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    sum(oi.item_discount_amount) as total_discount,
    avg(oi.quantity) as avg_qty
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1, 2
""", materialized="view", tags=[
    "scan:orders_items+customers+nations+regions", "joins:3", "agg:simple",
    "rows_sf1:35", "cols:6", "filter:none",
])

# orders_items + parts + suppliers + nations
add("join4_oi_parts_supp_nat", """
select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount, oi.quantity,
    p.part_brand_name, p.part_type_name,
    s.supplier_name,
    n.nation_name
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
""", materialized="view", tags=[
    "scan:orders_items+parts+suppliers+nations", "joins:3", "agg:none",
    "rows_sf1:6M", "cols:8", "filter:none",
])

add("join4_oi_parts_supp_nat_agg", """
select
    n.nation_name,
    p.part_brand_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
group by 1, 2
""", materialized="view", tags=[
    "scan:orders_items+parts+suppliers+nations", "joins:3", "agg:simple",
    "rows_sf1:625", "cols:5", "filter:none",
])

# 5-way join: oi + parts + suppliers + nations + regions
add("join5_oi_parts_supp_nat_reg", """
select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount,
    p.part_brand_name, p.part_type_name,
    s.supplier_name,
    n.nation_name, r.region_name
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
""", materialized="view", tags=[
    "scan:orders_items+parts+suppliers+nations+regions", "joins:4", "agg:none",
    "rows_sf1:6M", "cols:8", "filter:none",
])

add("join5_oi_parts_supp_nat_reg_agg", """
select
    r.region_name,
    p.part_type_name,
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.quantity) as avg_qty
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1, 2, 3
""", materialized="view", tags=[
    "scan:orders_items+parts+suppliers+nations+regions", "joins:4", "agg:simple",
    "rows_sf1:5250", "cols:6", "filter:none",
])


# === FAMILY 10: Subquery / CTE patterns ===

add("cte_top_customers", """
with customer_spend as (
    select
        customer_key,
        sum(gross_item_sales_amount) as total_spend,
        count(*) as item_count
    from {{ ref('orders_items') }}
    group by 1
)
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    cs.total_spend, cs.item_count
from {{ ref('customers') }} c
join customer_spend cs on c.customer_key = cs.customer_key
where cs.total_spend > 1000000
""", materialized="view", tags=[
    "scan:orders_items+customers", "joins:1", "agg:simple",
    "rows_sf1:50K", "cols:5", "filter:heavy",
])

add("cte_supplier_ranking", """
with supplier_sales as (
    select
        supplier_key,
        sum(gross_item_sales_amount) as total_sales,
        count(*) as item_count,
        avg(discount_percentage) as avg_discount
    from {{ ref('orders_items') }}
    group by 1
)
select
    s.supplier_key, s.supplier_name, s.nation_key,
    ss.total_sales, ss.item_count, ss.avg_discount,
    rank() over (order by ss.total_sales desc) as sales_rank
from {{ ref('suppliers') }} s
join supplier_sales ss on s.supplier_key = ss.supplier_key
""", materialized="view", tags=[
    "scan:orders_items+suppliers", "joins:1", "agg:multi",
    "rows_sf1:10K", "cols:7", "filter:none",
])

add("cte_part_popularity", """
with part_orders as (
    select
        part_key,
        count(*) as times_ordered,
        sum(quantity) as total_qty,
        sum(gross_item_sales_amount) as total_revenue
    from {{ ref('orders_items') }}
    group by 1
)
select
    p.part_key, p.part_name, p.part_brand_name, p.part_type_name,
    po.times_ordered, po.total_qty, po.total_revenue,
    rank() over (order by po.total_revenue desc) as revenue_rank,
    rank() over (order by po.times_ordered desc) as popularity_rank
from {{ ref('parts') }} p
join part_orders po on p.part_key = po.part_key
""", materialized="view", tags=[
    "scan:orders_items+parts", "joins:1", "agg:multi",
    "rows_sf1:200K", "cols:9", "filter:none",
])

add("cte_customer_order_stats", """
with order_stats as (
    select
        customer_key,
        count(*) as order_count,
        sum(order_amount) as total_amount,
        min(order_date) as first_order,
        max(order_date) as last_order,
        datediff(day, min(order_date), max(order_date)) as tenure_days
    from {{ ref('orders') }}
    group by 1
)
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    c.customer_account_balance,
    os.order_count, os.total_amount, os.first_order, os.last_order,
    os.tenure_days,
    os.total_amount / nullif(os.order_count, 0) as avg_order_value
from {{ ref('customers') }} c
join order_stats os on c.customer_key = os.customer_key
""", materialized="view", tags=[
    "scan:orders+customers", "joins:1", "agg:simple",
    "rows_sf1:150K", "cols:10", "filter:none",
])

add("cte_monthly_trend", """
with monthly as (
    select
        date_trunc('month', order_date) as month,
        count(*) as item_count,
        sum(gross_item_sales_amount) as total_sales,
        sum(item_discount_amount) as total_discount,
        sum(net_item_sales_amount) as total_net
    from {{ ref('orders_items') }}
    group by 1
)
select
    month,
    item_count,
    total_sales,
    total_discount,
    total_net,
    lag(total_sales) over (order by month) as prev_month_sales,
    total_sales - lag(total_sales) over (order by month) as sales_change,
    (total_sales - lag(total_sales) over (order by month)) / nullif(lag(total_sales) over (order by month), 0) as sales_pct_change
from monthly
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:multi",
    "rows_sf1:84", "cols:8", "filter:none",
])

add("cte_yoy_comparison", """
with yearly as (
    select
        date_trunc('year', order_date) as year,
        count(*) as item_count,
        sum(gross_item_sales_amount) as total_sales,
        sum(quantity) as total_qty
    from {{ ref('orders_items') }}
    group by 1
)
select
    year,
    item_count,
    total_sales,
    total_qty,
    lag(total_sales) over (order by year) as prev_year_sales,
    total_sales - lag(total_sales) over (order by year) as yoy_change
from yearly
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:multi",
    "rows_sf1:7", "cols:6", "filter:none",
])

add("cte_price_bands", """
with price_stats as (
    select
        part_key,
        avg(base_price) as avg_price,
        min(base_price) as min_price,
        max(base_price) as max_price,
        count(*) as sale_count
    from {{ ref('orders_items') }}
    group by 1
)
select
    p.part_key, p.part_name, p.part_brand_name,
    ps.avg_price, ps.min_price, ps.max_price, ps.sale_count,
    case
        when ps.avg_price < 500 then 'budget'
        when ps.avg_price < 1000 then 'mid-range'
        when ps.avg_price < 1500 then 'premium'
        else 'luxury'
    end as price_band
from {{ ref('parts') }} p
join price_stats ps on p.part_key = ps.part_key
""", materialized="view", tags=[
    "scan:orders_items+parts", "joins:1", "agg:simple",
    "rows_sf1:200K", "cols:8", "filter:none",
])

# Multi-CTE complex queries
add("cte_multi_revenue_analysis", """
with customer_revenue as (
    select customer_key, sum(gross_item_sales_amount) as revenue
    from {{ ref('orders_items') }}
    group by 1
),
segment_stats as (
    select
        c.customer_market_segment_name,
        count(*) as customer_count,
        sum(cr.revenue) as segment_revenue,
        avg(cr.revenue) as avg_revenue,
        min(cr.revenue) as min_revenue,
        max(cr.revenue) as max_revenue
    from {{ ref('customers') }} c
    join customer_revenue cr on c.customer_key = cr.customer_key
    group by 1
)
select
    customer_market_segment_name,
    customer_count,
    segment_revenue,
    avg_revenue,
    min_revenue,
    max_revenue,
    segment_revenue / nullif(sum(segment_revenue) over (), 0) as revenue_share
from segment_stats
""", materialized="view", tags=[
    "scan:orders_items+customers", "joins:1", "agg:multi",
    "rows_sf1:5", "cols:7", "filter:none",
])

add("cte_multi_supplier_perf", """
with supplier_items as (
    select
        supplier_key,
        count(*) as item_count,
        sum(gross_item_sales_amount) as total_sales,
        avg(discount_percentage) as avg_discount,
        sum(case when return_status_code = 'R' then 1 else 0 end) as return_count
    from {{ ref('orders_items') }}
    group by 1
),
supplier_detail as (
    select
        s.supplier_key, s.supplier_name, s.nation_key,
        si.item_count, si.total_sales, si.avg_discount, si.return_count,
        si.return_count::float / nullif(si.item_count, 0) as return_rate
    from {{ ref('suppliers') }} s
    join supplier_items si on s.supplier_key = si.supplier_key
)
select
    supplier_key, supplier_name, nation_key,
    item_count, total_sales, avg_discount, return_count, return_rate,
    rank() over (order by total_sales desc) as sales_rank,
    rank() over (order by return_rate) as quality_rank
from supplier_detail
""", materialized="view", tags=[
    "scan:orders_items+suppliers", "joins:1", "agg:multi",
    "rows_sf1:10K", "cols:10", "filter:none",
])


# === FAMILY 11: UNION / UNION ALL patterns ===

add("union_ship_modes", """
select 'AIR' as ship_mode, count(*) as cnt, sum(gross_item_sales_amount) as total
from {{ ref('orders_items') }} where ship_mode_name = 'AIR'
union all
select 'RAIL', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'RAIL'
union all
select 'TRUCK', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'TRUCK'
union all
select 'SHIP', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'SHIP'
union all
select 'MAIL', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'MAIL'
union all
select 'REG AIR', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'REG AIR'
union all
select 'FOB', count(*), sum(gross_item_sales_amount)
from {{ ref('orders_items') }} where ship_mode_name = 'FOB'
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:simple",
    "rows_sf1:7", "cols:3", "filter:light",
])

add("union_entity_counts", """
select 'customers' as entity, count(*) as cnt from {{ ref('customers') }}
union all
select 'orders', count(*) from {{ ref('orders') }}
union all
select 'parts', count(*) from {{ ref('parts') }}
union all
select 'suppliers', count(*) from {{ ref('suppliers') }}
union all
select 'order_items', count(*) from {{ ref('orders_items') }}
union all
select 'parts_suppliers', count(*) from {{ ref('parts_suppliers') }}
""", materialized="view", tags=[
    "scan:customers+orders+parts+suppliers+orders_items+parts_suppliers", "joins:0", "agg:simple",
    "rows_sf1:6", "cols:2", "filter:none",
])


# === FAMILY 12: HAVING clauses ===

add("having_big_customers", """
select
    customer_key,
    count(*) as order_count,
    sum(gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }}
group by 1
having count(*) > 100
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:simple",
    "rows_sf1:50K", "cols:3", "filter:heavy",
])

add("having_popular_parts", """
select
    part_key,
    count(*) as times_ordered,
    sum(quantity) as total_qty,
    sum(gross_item_sales_amount) as total_revenue
from {{ ref('orders_items') }}
group by 1
having sum(gross_item_sales_amount) > 500000
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:simple",
    "rows_sf1:50K", "cols:4", "filter:heavy",
])

add("having_active_suppliers", """
select
    supplier_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {{ ref('orders_items') }}
group by 1
having count(*) > 500
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:simple",
    "rows_sf1:5K", "cols:4", "filter:heavy",
])


# === FAMILY 13: CASE expressions ===

add("case_order_size", """
select
    order_key,
    order_amount,
    case
        when order_amount < 10000 then 'tiny'
        when order_amount < 50000 then 'small'
        when order_amount < 200000 then 'medium'
        when order_amount < 400000 then 'large'
        else 'xlarge'
    end as order_size_bucket,
    order_date, customer_key
from {{ ref('orders') }}
""", materialized="view", tags=[
    "scan:orders", "joins:0", "agg:none",
    "rows_sf1:1.5M", "cols:5", "filter:none",
])

add("case_shipping_speed", """
select
    order_item_key,
    order_date, ship_date, receipt_date,
    datediff(day, order_date, ship_date) as days_to_ship,
    datediff(day, ship_date, receipt_date) as days_in_transit,
    case
        when datediff(day, order_date, ship_date) <= 3 then 'express'
        when datediff(day, order_date, ship_date) <= 7 then 'standard'
        when datediff(day, order_date, ship_date) <= 14 then 'economy'
        else 'delayed'
    end as shipping_speed,
    gross_item_sales_amount
from {{ ref('orders_items') }}
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:none",
    "rows_sf1:6M", "cols:8", "filter:none",
])

add("case_discount_tier", """
select
    order_item_key,
    discount_percentage,
    case
        when discount_percentage = 0 then 'none'
        when discount_percentage <= 0.03 then 'low'
        when discount_percentage <= 0.06 then 'medium'
        when discount_percentage <= 0.08 then 'high'
        else 'very_high'
    end as discount_tier,
    gross_item_sales_amount,
    item_discount_amount
from {{ ref('orders_items') }}
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:none",
    "rows_sf1:6M", "cols:5", "filter:none",
])

add("case_agg_size_buckets", """
select
    case
        when order_amount < 10000 then 'tiny'
        when order_amount < 50000 then 'small'
        when order_amount < 200000 then 'medium'
        when order_amount < 400000 then 'large'
        else 'xlarge'
    end as size_bucket,
    count(*) as order_count,
    sum(order_amount) as total_amount,
    avg(order_amount) as avg_amount
from {{ ref('orders') }}
group by 1
""", materialized="view", tags=[
    "scan:orders", "joins:0", "agg:simple",
    "rows_sf1:5", "cols:4", "filter:none",
])


# === FAMILY 14: DISTINCT queries ===

add("distinct_ship_modes", """
select distinct ship_mode_name from {{ ref('orders_items') }}
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:none",
    "rows_sf1:7", "cols:1", "filter:none",
])

add("distinct_customer_segments", """
select distinct customer_market_segment_name from {{ ref('customers') }}
""", materialized="view", tags=[
    "scan:customers", "joins:0", "agg:none",
    "rows_sf1:5", "cols:1", "filter:none",
])

add("distinct_part_types", """
select distinct part_type_name from {{ ref('parts') }}
""", materialized="view", tags=[
    "scan:parts", "joins:0", "agg:none",
    "rows_sf1:150", "cols:1", "filter:none",
])

add("distinct_order_dates", """
select distinct order_date from {{ ref('orders') }} order by 1
""", materialized="view", tags=[
    "scan:orders", "joins:0", "agg:none",
    "rows_sf1:2500", "cols:1", "filter:none",
])

add("distinct_customer_nations", """
select distinct c.customer_key, n.nation_name
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
""", materialized="view", tags=[
    "scan:customers+nations", "joins:1", "agg:none",
    "rows_sf1:150K", "cols:2", "filter:none",
])


# === FAMILY 15: ORDER BY / LIMIT patterns (top-N) ===

add("top100_orders_by_amount", """
select
    order_key, order_date, customer_key, order_amount
from {{ ref('orders') }}
order by order_amount desc
limit 100
""", materialized="view", tags=[
    "scan:orders", "joins:0", "agg:none",
    "rows_sf1:100", "cols:4", "filter:heavy",
])

add("top100_items_by_sales", """
select
    order_item_key, order_key, part_key, supplier_key,
    gross_item_sales_amount, quantity
from {{ ref('orders_items') }}
order by gross_item_sales_amount desc
limit 100
""", materialized="view", tags=[
    "scan:orders_items", "joins:0", "agg:none",
    "rows_sf1:100", "cols:6", "filter:heavy",
])

add("top50_expensive_parts", """
select
    part_key, part_name, part_brand_name, retail_price
from {{ ref('parts') }}
order by retail_price desc
limit 50
""", materialized="view", tags=[
    "scan:parts", "joins:0", "agg:none",
    "rows_sf1:50", "cols:4", "filter:heavy",
])


# === FAMILY 16: EXISTS / NOT EXISTS / IN patterns ===

add("customers_with_orders", """
select c.customer_key, c.customer_name, c.customer_market_segment_name
from {{ ref('customers') }} c
where exists (
    select 1 from {{ ref('orders') }} o where o.customer_key = c.customer_key
)
""", materialized="view", tags=[
    "scan:customers+orders", "joins:1", "agg:none",
    "rows_sf1:100K", "cols:3", "filter:light",
])

add("customers_without_orders", """
select c.customer_key, c.customer_name, c.customer_market_segment_name
from {{ ref('customers') }} c
where not exists (
    select 1 from {{ ref('orders') }} o where o.customer_key = c.customer_key
)
""", materialized="view", tags=[
    "scan:customers+orders", "joins:1", "agg:none",
    "rows_sf1:50K", "cols:3", "filter:heavy",
])

add("parts_never_ordered", """
select p.part_key, p.part_name, p.part_brand_name, p.retail_price
from {{ ref('parts') }} p
where not exists (
    select 1 from {{ ref('orders_items') }} oi where oi.part_key = p.part_key
)
""", materialized="view", tags=[
    "scan:parts+orders_items", "joins:1", "agg:none",
    "rows_sf1:1K", "cols:4", "filter:heavy",
])

add("suppliers_high_volume", """
select s.supplier_key, s.supplier_name
from {{ ref('suppliers') }} s
where s.supplier_key in (
    select supplier_key from {{ ref('orders_items') }}
    group by 1 having count(*) > 1000
)
""", materialized="view", tags=[
    "scan:suppliers+orders_items", "joins:1", "agg:simple",
    "rows_sf1:5K", "cols:2", "filter:heavy",
])


# === FAMILY 17: LEFT JOIN patterns ===

add("left_join_orders_customers", """
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_market_segment_name
from {{ ref('orders') }} o
left join {{ ref('customers') }} c on o.customer_key = c.customer_key
""", materialized="view", tags=[
    "scan:orders+customers", "joins:1", "agg:none",
    "rows_sf1:1.5M", "cols:5", "filter:none",
])

add("left_join_parts_orders", """
select
    p.part_key, p.part_name, p.part_brand_name, p.retail_price,
    count(oi.order_item_key) as times_ordered,
    coalesce(sum(oi.quantity), 0) as total_qty
from {{ ref('parts') }} p
left join {{ ref('orders_items') }} oi on p.part_key = oi.part_key
group by 1, 2, 3, 4
""", materialized="view", tags=[
    "scan:parts+orders_items", "joins:1", "agg:simple",
    "rows_sf1:200K", "cols:6", "filter:none",
])


# === FAMILY 18: Self-referential patterns (same table, different aliases) ===

add("self_join_orders_consecutive", """
select
    o1.order_key as order_key_1,
    o2.order_key as order_key_2,
    o1.customer_key,
    o1.order_date as date_1,
    o2.order_date as date_2,
    datediff(day, o1.order_date, o2.order_date) as days_between
from {{ ref('orders') }} o1
join {{ ref('orders') }} o2
    on o1.customer_key = o2.customer_key
    and o2.order_date > o1.order_date
    and o2.order_date <= dateadd(day, 30, o1.order_date)
""", materialized="view", tags=[
    "scan:orders", "joins:1", "agg:none",
    "rows_sf1:500K", "cols:6", "filter:heavy",
])


# === NOW: Generate materialized TABLE variants of key queries ===
# These are the CTAS (CREATE TABLE AS SELECT) write-path queries.

# Strategy: take a representative subset of the view queries and make them tables.
# This gives us the write-path coverage. We'll generate ~375 tables.

# Table versions of single-table scans
for src_table, cols, est_rows in [
    ("orders_items", "order_item_key, order_key, order_date, customer_key, part_key, supplier_key, quantity, base_price, gross_item_sales_amount, net_item_sales_amount", "6M"),
    ("orders", "order_key, order_date, customer_key, order_status_code, order_priority_code, order_amount", "1.5M"),
    ("customers", "customer_key, customer_name, nation_key, customer_account_balance, customer_market_segment_name", "150K"),
    ("parts", "part_key, part_name, part_brand_name, part_type_name, part_size, retail_price", "200K"),
    ("suppliers", "supplier_key, supplier_name, nation_key, supplier_account_balance", "10K"),
    ("parts_suppliers", "part_supplier_key, part_key, supplier_key, supplier_cost_amount, supplier_availabe_quantity", "800K"),
]:
    short = src_table.replace("orders_items", "oi").replace("orders", "ord").replace("customers", "cust").replace("parts_suppliers", "ps").replace("parts", "pt").replace("suppliers", "supp")
    ncols = len(cols.split(","))
    add(f"tbl_{short}_full", f"""
select {cols}
from {{{{ ref('{src_table}') }}}}
""", materialized="table", tags=[
        f"scan:{src_table}", "joins:0", "agg:none",
        f"rows_sf1:{est_rows}", f"cols:{ncols}", "filter:none",
    ])

# Table versions of filtered single-table scans
filter_table_variants = [
    ("tbl_oi_recent", "orders_items",
     "order_item_key, order_key, order_date, customer_key, quantity, gross_item_sales_amount",
     "ship_date >= dateadd(day, -90, '1998-12-01')", "1.5M", "light"),
    ("tbl_oi_returned", "orders_items",
     "order_item_key, order_key, customer_key, quantity, gross_item_sales_amount, return_status_code",
     "return_status_code = 'R'", "1.5M", "light"),
    ("tbl_oi_high_value", "orders_items",
     "order_item_key, order_key, customer_key, part_key, gross_item_sales_amount",
     "gross_item_sales_amount > 50000", "600K", "light"),
    ("tbl_ord_fulfilled", "orders",
     "order_key, order_date, customer_key, order_amount",
     "order_status_code = 'F'", "750K", "light"),
    ("tbl_ord_high_priority", "orders",
     "order_key, order_date, customer_key, order_amount, order_priority_code",
     "order_priority_code in ('1-URGENT', '2-HIGH')", "600K", "light"),
    ("tbl_cust_high_bal", "customers",
     "customer_key, customer_name, customer_account_balance",
     "customer_account_balance > 9000", "15K", "heavy"),
    ("tbl_pt_brass", "parts",
     "part_key, part_name, part_type_name, retail_price",
     "part_type_name like '%BRASS%'", "25K", "light"),
]

for name, src_table, cols, predicate, est_rows, ftype in filter_table_variants:
    ncols = len(cols.split(","))
    add(name, f"""
select {cols}
from {{{{ ref('{src_table}') }}}}
where {predicate}
""", materialized="table", tags=[
        f"scan:{src_table}", "joins:0", "agg:none",
        f"rows_sf1:{est_rows}", f"cols:{ncols}", f"filter:{ftype}",
    ])

# Table versions of aggregations
agg_table_variants = [
    ("tbl_oi_agg_customer", "orders_items",
     "customer_key, count(*) as item_count, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales, min(order_date) as first_order, max(order_date) as last_order",
     "customer_key", "150K", "6"),
    ("tbl_oi_agg_part", "orders_items",
     "part_key, count(*) as times_ordered, sum(quantity) as total_qty, avg(base_price) as avg_price, sum(gross_item_sales_amount) as total_revenue",
     "part_key", "200K", "5"),
    ("tbl_oi_agg_supplier", "orders_items",
     "supplier_key, count(*) as items_supplied, sum(gross_item_sales_amount) as total_sales",
     "supplier_key", "10K", "3"),
    ("tbl_oi_agg_month", "orders_items",
     "date_trunc('month', order_date) as month, count(*) as cnt, sum(gross_item_sales_amount) as total_sales, avg(discount_percentage) as avg_discount",
     "1", "84", "4"),
    ("tbl_oi_agg_ship_mode", "orders_items",
     "ship_mode_name, count(*) as cnt, sum(quantity) as total_qty, sum(gross_item_sales_amount) as total_sales",
     "ship_mode_name", "7", "4"),
    ("tbl_ord_agg_customer", "orders",
     "customer_key, count(*) as order_count, sum(order_amount) as total_spent, min(order_date) as first_order, max(order_date) as last_order",
     "customer_key", "150K", "5"),
    ("tbl_ord_agg_month", "orders",
     "date_trunc('month', order_date) as month, count(*) as cnt, sum(order_amount) as total_amount",
     "1", "84", "3"),
    ("tbl_ps_agg_part", "parts_suppliers",
     "part_key, count(*) as supplier_count, avg(supplier_cost_amount) as avg_cost",
     "part_key", "200K", "3"),
    ("tbl_cust_agg_segment", "customers",
     "customer_market_segment_name, count(*) as cnt, avg(customer_account_balance) as avg_balance",
     "customer_market_segment_name", "5", "3"),
    ("tbl_pt_agg_brand", "parts",
     "part_brand_name, count(*) as cnt, avg(retail_price) as avg_price",
     "part_brand_name", "25", "3"),
]

for name, src_table, select_expr, group_col, est_rows, ncols in agg_table_variants:
    add(name, f"""
select {select_expr}
from {{{{ ref('{src_table}') }}}}
group by {group_col}
""", materialized="table", tags=[
        f"scan:{src_table}", "joins:0", "agg:simple",
        f"rows_sf1:{est_rows}", f"cols:{ncols}", "filter:none",
    ])

# Table versions of joins
join_table_variants = [
    ("tbl_join_ord_cust", """
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_market_segment_name
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
""", "scan:orders+customers", "joins:1", "1.5M", "5"),
    ("tbl_join_oi_parts", """
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount,
    p.part_name, p.part_brand_name
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
""", "scan:orders_items+parts", "joins:1", "6M", "6"),
    ("tbl_join_oi_supp", """
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount,
    s.supplier_name, s.nation_key
from {{ ref('orders_items') }} oi
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
""", "scan:orders_items+suppliers", "joins:1", "6M", "6"),
    ("tbl_join_ps_nat", """
select
    ps.part_supplier_key, ps.part_key, ps.supplier_key,
    ps.supplier_cost_amount,
    n.nation_name
from {{ ref('parts_suppliers') }} ps
join {{ ref('nations') }} n on ps.nation_key = n.nation_key
""", "scan:parts_suppliers+nations", "joins:1", "800K", "5"),
    ("tbl_join3_ord_cust_nat", """
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name,
    n.nation_name
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
""", "scan:orders+customers+nations", "joins:2", "1.5M", "5"),
    ("tbl_join3_oi_parts_supp", """
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount,
    p.part_brand_name,
    s.supplier_name
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
""", "scan:orders_items+parts+suppliers", "joins:2", "6M", "6"),
    ("tbl_join4_oi_cust_nat_reg", """
select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount,
    c.customer_market_segment_name,
    n.nation_name, r.region_name
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
""", "scan:orders_items+customers+nations+regions", "joins:3", "6M", "6"),
]

for name, body, scan, joins, est_rows, ncols in join_table_variants:
    add(name, body, materialized="table", tags=[
        scan, joins, "agg:none",
        f"rows_sf1:{est_rows}", f"cols:{ncols}", "filter:none",
    ])

# Table versions of join+agg combos
join_agg_table_variants = [
    ("tbl_join_ord_cust_agg_seg", """
select
    c.customer_market_segment_name,
    count(*) as order_count,
    sum(o.order_amount) as total_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
group by 1
""", "scan:orders+customers", "joins:1", "5", "3"),
    ("tbl_join_oi_parts_agg_brand", """
select
    p.part_brand_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
group by 1
""", "scan:orders_items+parts", "joins:1", "25", "3"),
    ("tbl_join3_oi_cust_nat_agg", """
select
    n.nation_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1
""", "scan:orders_items+customers+nations", "joins:2", "25", "3"),
    ("tbl_join4_oi_ps_nat_reg_agg", """
select
    r.region_name,
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1, 2
""", "scan:orders_items+customers+nations+regions", "joins:3", "35", "4"),
]

for name, body, scan, joins, est_rows, ncols in join_agg_table_variants:
    add(name, body, materialized="table", tags=[
        scan, joins, "agg:simple",
        f"rows_sf1:{est_rows}", f"cols:{ncols}", "filter:none",
    ])

# Table versions of window queries
win_table_variants = [
    ("tbl_oi_win_rank_customer", """
select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    row_number() over (partition by customer_key order by gross_item_sales_amount desc) as sales_rank
from {{ ref('orders_items') }}
""", "scan:orders_items", "6M", "5"),
    ("tbl_ord_win_customer_seq", """
select
    order_key, customer_key, order_date, order_amount,
    row_number() over (partition by customer_key order by order_date) as order_seq,
    sum(order_amount) over (partition by customer_key order by order_date rows unbounded preceding) as cumulative_spend
from {{ ref('orders') }}
""", "scan:orders", "1.5M", "6"),
]

for name, body, scan, est_rows, ncols in win_table_variants:
    add(name, body, materialized="table", tags=[
        scan, "joins:0", "agg:window",
        f"rows_sf1:{est_rows}", f"cols:{ncols}", "filter:none",
    ])

# Table versions of CTE queries
cte_table_variants = [
    ("tbl_cte_top_customers", """
with customer_spend as (
    select
        customer_key,
        sum(gross_item_sales_amount) as total_spend,
        count(*) as item_count
    from {{ ref('orders_items') }}
    group by 1
)
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    cs.total_spend, cs.item_count
from {{ ref('customers') }} c
join customer_spend cs on c.customer_key = cs.customer_key
where cs.total_spend > 1000000
""", "scan:orders_items+customers", "joins:1", "simple", "50K", "5", "heavy"),
    ("tbl_cte_supplier_ranking", """
with supplier_sales as (
    select
        supplier_key,
        sum(gross_item_sales_amount) as total_sales,
        count(*) as item_count
    from {{ ref('orders_items') }}
    group by 1
)
select
    s.supplier_key, s.supplier_name,
    ss.total_sales, ss.item_count,
    rank() over (order by ss.total_sales desc) as sales_rank
from {{ ref('suppliers') }} s
join supplier_sales ss on s.supplier_key = ss.supplier_key
""", "scan:orders_items+suppliers", "joins:1", "multi", "10K", "5", "none"),
    ("tbl_cte_customer_stats", """
with order_stats as (
    select
        customer_key,
        count(*) as order_count,
        sum(order_amount) as total_amount,
        min(order_date) as first_order,
        max(order_date) as last_order
    from {{ ref('orders') }}
    group by 1
)
select
    c.customer_key, c.customer_name, c.customer_market_segment_name,
    os.order_count, os.total_amount, os.first_order, os.last_order
from {{ ref('customers') }} c
join order_stats os on c.customer_key = os.customer_key
""", "scan:orders+customers", "joins:1", "simple", "150K", "7", "none"),
]

for name, body, scan, joins, agg, est_rows, ncols, ftype in cte_table_variants:
    add(name, body, materialized="table", tags=[
        scan, joins, f"agg:{agg}",
        f"rows_sf1:{est_rows}", f"cols:{ncols}", f"filter:{ftype}",
    ])


# === NOW: Parameterized variants to reach ~1000 ===
# Generate variants by varying filter predicates, group-by dimensions, and column selections.

# Variant generator: for each base ODS table, create filtered + agg combos
# with different predicates and group-bys.

# Date range variants on orders_items
date_ranges = [
    ("1992", "'1992-01-01'", "'1992-12-31'"),
    ("1993", "'1993-01-01'", "'1993-12-31'"),
    ("1994", "'1994-01-01'", "'1994-12-31'"),
    ("1995", "'1995-01-01'", "'1995-12-31'"),
    ("1996", "'1996-01-01'", "'1996-12-31'"),
    ("1997", "'1997-01-01'", "'1997-12-31'"),
    ("1998", "'1998-01-01'", "'1998-12-01'"),
    ("h1_1993", "'1993-01-01'", "'1993-06-30'"),
    ("h2_1993", "'1993-07-01'", "'1993-12-31'"),
    ("h1_1994", "'1994-01-01'", "'1994-06-30'"),
    ("h2_1994", "'1994-07-01'", "'1994-12-31'"),
    ("h1_1995", "'1995-01-01'", "'1995-06-30'"),
    ("h2_1995", "'1995-07-01'", "'1995-12-31'"),
    ("h1_1996", "'1996-01-01'", "'1996-06-30'"),
    ("h2_1996", "'1996-07-01'", "'1996-12-31'"),
    ("h1_1997", "'1997-01-01'", "'1997-06-30'"),
    ("h2_1997", "'1997-07-01'", "'1997-12-31'"),
]

# View: filtered scans by date range on orders_items
for label, start, end in date_ranges:
    add(f"oi_date_{label}", f"""
select
    order_item_key, order_key, order_date, customer_key, part_key,
    supplier_key, quantity, gross_item_sales_amount, net_item_sales_amount
from {{{{ ref('orders_items') }}}}
where order_date >= {start} and order_date <= {end}
""", materialized="view", tags=[
        "scan:orders_items", "joins:0", "agg:none",
        "rows_sf1:900K", "cols:9", "filter:light",
    ])

# View: agg by date range on orders_items
for label, start, end in date_ranges:
    add(f"oi_agg_date_{label}", f"""
select
    customer_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {{{{ ref('orders_items') }}}}
where order_date >= {start} and order_date <= {end}
group by 1
""", materialized="view", tags=[
        "scan:orders_items", "joins:0", "agg:simple",
        "rows_sf1:100K", "cols:4", "filter:light",
    ])

# Table: agg by date range on orders_items (subset)
for label, start, end in date_ranges[:7]:  # yearly only
    add(f"tbl_oi_agg_date_{label}", f"""
select
    customer_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    sum(quantity) as total_qty
from {{{{ ref('orders_items') }}}}
where order_date >= {start} and order_date <= {end}
group by 1
""", materialized="table", tags=[
        "scan:orders_items", "joins:0", "agg:simple",
        "rows_sf1:100K", "cols:4", "filter:light",
    ])

# Date range variants on orders
for label, start, end in date_ranges:
    add(f"ord_date_{label}", f"""
select
    order_key, order_date, customer_key, order_status_code,
    order_amount
from {{{{ ref('orders') }}}}
where order_date >= {start} and order_date <= {end}
""", materialized="view", tags=[
        "scan:orders", "joins:0", "agg:none",
        "rows_sf1:220K", "cols:5", "filter:light",
    ])

# Join + date range variants: orders_items + customers by date
for label, start, end in date_ranges[:7]:  # yearly
    add(f"join_oi_cust_date_{label}", f"""
select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    c.customer_name, c.customer_market_segment_name
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where oi.order_date >= {start} and oi.order_date <= {end}
""", materialized="view", tags=[
        "scan:orders_items+customers", "joins:1", "agg:none",
        "rows_sf1:900K", "cols:5", "filter:light",
    ])

# Join + date range + agg: orders_items + customers by date, grouped by segment
for label, start, end in date_ranges[:7]:
    add(f"join_oi_cust_agg_seg_date_{label}", f"""
select
    c.customer_market_segment_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales,
    avg(oi.discount_percentage) as avg_discount
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where oi.order_date >= {start} and oi.order_date <= {end}
group by 1
""", materialized="view", tags=[
        "scan:orders_items+customers", "joins:1", "agg:simple",
        "rows_sf1:5", "cols:4", "filter:light",
    ])

# Table: join + date + agg (subset)
for label, start, end in date_ranges[:4]:
    add(f"tbl_join_oi_cust_agg_date_{label}", f"""
select
    c.customer_market_segment_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where oi.order_date >= {start} and oi.order_date <= {end}
group by 1
""", materialized="table", tags=[
        "scan:orders_items+customers", "joins:1", "agg:simple",
        "rows_sf1:5", "cols:3", "filter:light",
    ])

# Ship mode x date combinations for tables
ship_modes = ["AIR", "RAIL", "TRUCK", "SHIP", "MAIL", "REG AIR", "FOB"]
for mode in ship_modes:
    safe_mode = mode.lower().replace(" ", "_")
    add(f"tbl_oi_{safe_mode}", f"""
select
    order_item_key, order_key, order_date, customer_key,
    quantity, gross_item_sales_amount
from {{{{ ref('orders_items') }}}}
where ship_mode_name = '{mode}'
""", materialized="table", tags=[
        "scan:orders_items", "joins:0", "agg:none",
        "rows_sf1:860K", "cols:6", "filter:light",
    ])

    add(f"tbl_oi_{safe_mode}_agg_month", f"""
select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}}
where ship_mode_name = '{mode}'
group by 1
""", materialized="table", tags=[
        "scan:orders_items", "joins:0", "agg:simple",
        "rows_sf1:84", "cols:3", "filter:light",
    ])

# Order priority x status combinations
priorities = ["1-URGENT", "2-HIGH", "3-MEDIUM", "4-NOT SPECIFIED", "5-LOW"]
for prio in priorities:
    safe_prio = prio.lower().replace("-", "_").replace(" ", "_")
    add(f"ord_priority_{safe_prio}", f"""
select
    order_key, order_date, customer_key, order_amount
from {{{{ ref('orders') }}}}
where order_priority_code = '{prio}'
""", materialized="view", tags=[
        "scan:orders", "joins:0", "agg:none",
        "rows_sf1:300K", "cols:4", "filter:light",
    ])

    add(f"tbl_ord_priority_{safe_prio}_agg", f"""
select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(order_amount) as total_amount
from {{{{ ref('orders') }}}}
where order_priority_code = '{prio}'
group by 1
""", materialized="table", tags=[
        "scan:orders", "joins:0", "agg:simple",
        "rows_sf1:84", "cols:3", "filter:light",
    ])

# Market segment variants
segments = ["AUTOMOBILE", "BUILDING", "FURNITURE", "HOUSEHOLD", "MACHINERY"]
for seg in segments:
    safe_seg = seg.lower()
    add(f"cust_seg_{safe_seg}", f"""
select
    customer_key, customer_name, customer_account_balance, nation_key
from {{{{ ref('customers') }}}}
where customer_market_segment_name = '{seg}'
""", materialized="view", tags=[
        "scan:customers", "joins:0", "agg:none",
        "rows_sf1:30K", "cols:4", "filter:light",
    ])

    add(f"join_ord_seg_{safe_seg}", f"""
select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name
from {{{{ ref('orders') }}}} o
join {{{{ ref('customers') }}}} c on o.customer_key = c.customer_key
where c.customer_market_segment_name = '{seg}'
""", materialized="view", tags=[
        "scan:orders+customers", "joins:1", "agg:none",
        "rows_sf1:300K", "cols:4", "filter:light",
    ])

    add(f"tbl_join_oi_seg_{safe_seg}", f"""
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount, oi.discount_percentage
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where c.customer_market_segment_name = '{seg}'
""", materialized="table", tags=[
        "scan:orders_items+customers", "joins:1", "agg:none",
        "rows_sf1:1.2M", "cols:5", "filter:light",
    ])

    add(f"tbl_join_oi_seg_{safe_seg}_agg", f"""
select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where c.customer_market_segment_name = '{seg}'
group by 1
""", materialized="table", tags=[
        "scan:orders_items+customers", "joins:1", "agg:simple",
        "rows_sf1:84", "cols:3", "filter:light",
    ])

# Brand variants for parts
brands = [f"Brand#{i}{j}" for i in range(1, 6) for j in range(1, 6)]
for brand in brands[:20]:  # 20 brands
    safe_brand = brand.lower().replace("#", "")
    add(f"pt_brand_{safe_brand}", f"""
select
    part_key, part_name, part_type_name, part_size, retail_price
from {{{{ ref('parts') }}}}
where part_brand_name = '{brand}'
""", materialized="view", tags=[
        "scan:parts", "joins:0", "agg:none",
        "rows_sf1:8K", "cols:5", "filter:heavy",
    ])

# Parts + orders_items by brand (tables)
for brand in brands[:10]:  # 10 brands
    safe_brand = brand.lower().replace("#", "")
    add(f"tbl_oi_brand_{safe_brand}", f"""
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('parts') }}}} p on oi.part_key = p.part_key
where p.part_brand_name = '{brand}'
""", materialized="table", tags=[
        "scan:orders_items+parts", "joins:1", "agg:none",
        "rows_sf1:240K", "cols:4", "filter:heavy",
    ])

# Region-based joins
regions_list = ["AFRICA", "AMERICA", "ASIA", "EUROPE", "MIDDLE EAST"]
for region in regions_list:
    safe_reg = region.lower().replace(" ", "_")
    add(f"join_oi_cust_reg_{safe_reg}", f"""
select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    c.customer_name
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where r.region_name = '{region}'
""", materialized="view", tags=[
        "scan:orders_items+customers+nations+regions", "joins:3", "agg:none",
        "rows_sf1:1.2M", "cols:4", "filter:light",
    ])

    add(f"tbl_join_oi_cust_reg_{safe_reg}", f"""
select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    c.customer_name
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where r.region_name = '{region}'
""", materialized="table", tags=[
        "scan:orders_items+customers+nations+regions", "joins:3", "agg:none",
        "rows_sf1:1.2M", "cols:4", "filter:light",
    ])

    add(f"tbl_join_oi_cust_reg_{safe_reg}_agg", f"""
select
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where r.region_name = '{region}'
group by 1
""", materialized="table", tags=[
        "scan:orders_items+customers+nations+regions", "joins:3", "agg:simple",
        "rows_sf1:7", "cols:3", "filter:light",
    ])

# Supplier region-based joins
for region in regions_list:
    safe_reg = region.lower().replace(" ", "_")
    add(f"join_oi_supp_reg_{safe_reg}", f"""
select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount,
    s.supplier_name
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('suppliers') }}}} s on oi.supplier_key = s.supplier_key
join {{{{ ref('nations') }}}} n on s.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where r.region_name = '{region}'
""", materialized="view", tags=[
        "scan:orders_items+suppliers+nations+regions", "joins:3", "agg:none",
        "rows_sf1:1.2M", "cols:4", "filter:light",
    ])


# === Cross-product date x region for tables (to boost table count) ===
for region in regions_list:
    safe_reg = region.lower().replace(" ", "_")
    for label, start, end in date_ranges[:4]:  # first 4 years x 5 regions = 20
        add(f"tbl_oi_{safe_reg}_{label}", f"""
select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount, oi.quantity
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where r.region_name = '{region}' and oi.order_date >= {start} and oi.order_date <= {end}
""", materialized="table", tags=[
            "scan:orders_items+customers+nations+regions", "joins:3", "agg:none",
            "rows_sf1:180K", "cols:4", "filter:heavy",
        ])


# === Window function variants for more diversity ===

# Percentile variants by different dimensions
for dim, partition_col, order_col in [
    ("customer_sales", "customer_key", "gross_item_sales_amount"),
    ("part_qty", "part_key", "quantity"),
    ("supplier_discount", "supplier_key", "discount_percentage"),
    ("month_sales", "date_trunc('month', order_date)", "gross_item_sales_amount"),
]:
    add(f"oi_win_pctile_{dim}", f"""
select
    order_item_key, {partition_col} as dim_key, {order_col} as measure,
    percent_rank() over (partition by {partition_col} order by {order_col}) as pct_rank,
    cume_dist() over (partition by {partition_col} order by {order_col}) as cum_dist
from {{{{ ref('orders_items') }}}}
""", materialized="view", tags=[
        "scan:orders_items", "joins:0", "agg:window",
        "rows_sf1:6M", "cols:5", "filter:none",
    ])

# First/last value variants
for dim, partition_col in [
    ("by_customer", "customer_key"),
    ("by_part", "part_key"),
    ("by_supplier", "supplier_key"),
]:
    add(f"oi_win_first_last_{dim}", f"""
select
    order_item_key, {partition_col} as dim_key, order_date,
    gross_item_sales_amount,
    first_value(gross_item_sales_amount) over (partition by {partition_col} order by order_date) as first_sale,
    last_value(gross_item_sales_amount) over (partition by {partition_col} order by order_date rows between unbounded preceding and unbounded following) as last_sale
from {{{{ ref('orders_items') }}}}
""", materialized="view", tags=[
        "scan:orders_items", "joins:0", "agg:window",
        "rows_sf1:6M", "cols:6", "filter:none",
    ])


# === FAMILY 19: More cross-product variants to reach ~1000 ===

# Date x ship mode views (17 dates x 7 modes = 119)
for label, start, end in date_ranges:
    for mode in ship_modes:
        safe_mode = mode.lower().replace(" ", "_")
        add(f"oi_{label}_{safe_mode}", f"""
select
    order_item_key, order_date, customer_key, quantity,
    gross_item_sales_amount
from {{{{ ref('orders_items') }}}}
where order_date >= {start} and order_date <= {end}
    and ship_mode_name = '{mode}'
""", materialized="view", tags=[
            "scan:orders_items", "joins:0", "agg:none",
            "rows_sf1:125K", "cols:5", "filter:heavy",
        ])

# Date x segment views (17 dates x 5 segments = 85)
for label, start, end in date_ranges:
    for seg in segments:
        safe_seg = seg.lower()
        add(f"oi_{label}_{safe_seg}", f"""
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where oi.order_date >= {start} and oi.order_date <= {end}
    and c.customer_market_segment_name = '{seg}'
""", materialized="view", tags=[
            "scan:orders_items+customers", "joins:1", "agg:none",
            "rows_sf1:180K", "cols:4", "filter:heavy",
        ])

# Date x segment agg tables (7 yearly x 5 segments = 35)
for label, start, end in date_ranges[:7]:
    for seg in segments:
        safe_seg = seg.lower()
        add(f"tbl_oi_{label}_{safe_seg}_agg", f"""
select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where oi.order_date >= {start} and oi.order_date <= {end}
    and c.customer_market_segment_name = '{seg}'
group by 1
""", materialized="table", tags=[
            "scan:orders_items+customers", "joins:1", "agg:simple",
            "rows_sf1:12", "cols:3", "filter:heavy",
        ])

# Region x date agg views (5 regions x 7 years = 35)
for region in regions_list:
    safe_reg = region.lower().replace(" ", "_")
    for label, start, end in date_ranges[:7]:
        add(f"join_oi_reg_{safe_reg}_agg_{label}", f"""
select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where r.region_name = '{region}'
    and oi.order_date >= {start} and oi.order_date <= {end}
group by 1
""", materialized="view", tags=[
            "scan:orders_items+customers+nations+regions", "joins:3", "agg:simple",
            "rows_sf1:12", "cols:3", "filter:heavy",
        ])

# Brand x date views (10 brands x 7 years = 70)
for brand in brands[:10]:
    safe_brand = brand.lower().replace("#", "")
    for label, start, end in date_ranges[:7]:
        add(f"oi_brand_{safe_brand}_{label}", f"""
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('parts') }}}} p on oi.part_key = p.part_key
where p.part_brand_name = '{brand}'
    and oi.order_date >= {start} and oi.order_date <= {end}
""", materialized="view", tags=[
            "scan:orders_items+parts", "joins:1", "agg:none",
            "rows_sf1:35K", "cols:4", "filter:heavy",
        ])

# Priority x date tables (5 priorities x 7 years = 35)
for prio in priorities:
    safe_prio = prio.lower().replace("-", "_").replace(" ", "_")
    for label, start, end in date_ranges[:7]:
        add(f"tbl_ord_{safe_prio}_{label}", f"""
select
    order_key, order_date, customer_key, order_amount
from {{{{ ref('orders') }}}}
where order_priority_code = '{prio}'
    and order_date >= {start} and order_date <= {end}
""", materialized="table", tags=[
            "scan:orders", "joins:0", "agg:none",
            "rows_sf1:45K", "cols:4", "filter:heavy",
        ])

# Window + date range variants (7 years)
for label, start, end in date_ranges[:7]:
    add(f"oi_win_rank_date_{label}", f"""
select
    order_item_key, customer_key, order_date, gross_item_sales_amount,
    row_number() over (partition by customer_key order by gross_item_sales_amount desc) as sales_rank
from {{{{ ref('orders_items') }}}}
where order_date >= {start} and order_date <= {end}
""", materialized="view", tags=[
        "scan:orders_items", "joins:0", "agg:window",
        "rows_sf1:900K", "cols:5", "filter:light",
    ])

# Segment x region views (5 x 5 = 25)
for seg in segments:
    safe_seg = seg.lower()
    for region in regions_list:
        safe_reg = region.lower().replace(" ", "_")
        add(f"oi_seg_{safe_seg}_reg_{safe_reg}", f"""
select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount, oi.quantity
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where c.customer_market_segment_name = '{seg}'
    and r.region_name = '{region}'
""", materialized="view", tags=[
            "scan:orders_items+customers+nations+regions", "joins:3", "agg:none",
            "rows_sf1:240K", "cols:4", "filter:heavy",
        ])

# Segment x region agg tables (5 x 5 = 25)
for seg in segments:
    safe_seg = seg.lower()
    for region in regions_list:
        safe_reg = region.lower().replace(" ", "_")
        add(f"tbl_oi_seg_{safe_seg}_reg_{safe_reg}_agg", f"""
select
    date_trunc('year', oi.order_date) as year,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where c.customer_market_segment_name = '{seg}'
    and r.region_name = '{region}'
group by 1
""", materialized="table", tags=[
            "scan:orders_items+customers+nations+regions", "joins:3", "agg:simple",
            "rows_sf1:7", "cols:3", "filter:heavy",
        ])

# Ship mode x region views (7 x 5 = 35)
for mode in ship_modes:
    safe_mode = mode.lower().replace(" ", "_")
    for region in regions_list:
        safe_reg = region.lower().replace(" ", "_")
        add(f"oi_ship_{safe_mode}_reg_{safe_reg}", f"""
select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
join {{{{ ref('nations') }}}} n on c.nation_key = n.nation_key
join {{{{ ref('regions') }}}} r on n.region_key = r.region_key
where oi.ship_mode_name = '{mode}'
    and r.region_name = '{region}'
""", materialized="view", tags=[
            "scan:orders_items+customers+nations+regions", "joins:3", "agg:none",
            "rows_sf1:170K", "cols:3", "filter:heavy",
        ])

# Remaining brand variants (views) to fill up
for brand in brands[20:]:  # brands 21-25 = 5 more
    safe_brand = brand.lower().replace("#", "")
    add(f"pt_brand_{safe_brand}", f"""
select
    part_key, part_name, part_type_name, part_size, retail_price
from {{{{ ref('parts') }}}}
where part_brand_name = '{brand}'
""", materialized="view", tags=[
        "scan:parts", "joins:0", "agg:none",
        "rows_sf1:8K", "cols:5", "filter:heavy",
    ])

# More brand x orders_items (brands 11-25 = 15)
for brand in brands[10:]:
    safe_brand = brand.lower().replace("#", "")
    add(f"tbl_oi_brand_{safe_brand}", f"""
select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('parts') }}}} p on oi.part_key = p.part_key
where p.part_brand_name = '{brand}'
""", materialized="table", tags=[
        "scan:orders_items+parts", "joins:1", "agg:none",
        "rows_sf1:240K", "cols:4", "filter:heavy",
    ])


# === FAMILY 20: More variants for count target ===

# Priority x segment views (5 x 5 = 25)
for prio in priorities:
    safe_prio = prio.lower().replace("-", "_").replace(" ", "_")
    for seg in segments:
        safe_seg = seg.lower()
        add(f"ord_prio_{safe_prio}_seg_{safe_seg}", f"""
select
    o.order_key, o.order_date, o.order_amount
from {{{{ ref('orders') }}}} o
join {{{{ ref('customers') }}}} c on o.customer_key = c.customer_key
where o.order_priority_code = '{prio}'
    and c.customer_market_segment_name = '{seg}'
""", materialized="view", tags=[
            "scan:orders+customers", "joins:1", "agg:none",
            "rows_sf1:60K", "cols:3", "filter:heavy",
        ])

# Priority x segment agg tables (5 x 5 = 25)
for prio in priorities:
    safe_prio = prio.lower().replace("-", "_").replace(" ", "_")
    for seg in segments:
        safe_seg = seg.lower()
        add(f"tbl_ord_prio_{safe_prio}_seg_{safe_seg}_agg", f"""
select
    date_trunc('month', o.order_date) as month,
    count(*) as cnt,
    sum(o.order_amount) as total_amount
from {{{{ ref('orders') }}}} o
join {{{{ ref('customers') }}}} c on o.customer_key = c.customer_key
where o.order_priority_code = '{prio}'
    and c.customer_market_segment_name = '{seg}'
group by 1
""", materialized="table", tags=[
            "scan:orders+customers", "joins:1", "agg:simple",
            "rows_sf1:84", "cols:3", "filter:heavy",
        ])

# Ship mode x segment views (7 x 5 = 35)
for mode in ship_modes:
    safe_mode = mode.lower().replace(" ", "_")
    for seg in segments:
        safe_seg = seg.lower()
        add(f"oi_ship_{safe_mode}_seg_{safe_seg}", f"""
select
    oi.order_item_key, oi.order_date, oi.gross_item_sales_amount
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where oi.ship_mode_name = '{mode}'
    and c.customer_market_segment_name = '{seg}'
""", materialized="view", tags=[
            "scan:orders_items+customers", "joins:1", "agg:none",
            "rows_sf1:170K", "cols:3", "filter:heavy",
        ])

# Ship mode x segment agg tables (7 x 5 = 35)
for mode in ship_modes:
    safe_mode = mode.lower().replace(" ", "_")
    for seg in segments:
        safe_seg = seg.lower()
        add(f"tbl_oi_ship_{safe_mode}_seg_{safe_seg}_agg", f"""
select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{{{ ref('orders_items') }}}} oi
join {{{{ ref('customers') }}}} c on oi.customer_key = c.customer_key
where oi.ship_mode_name = '{mode}'
    and c.customer_market_segment_name = '{seg}'
group by 1
""", materialized="table", tags=[
            "scan:orders_items+customers", "joins:1", "agg:simple",
            "rows_sf1:84", "cols:3", "filter:heavy",
        ])


# === Minimal subset for quick smoke tests ===
# ~25 models covering every key dimension: tables/views, join counts, agg types,
# big/small scans, filters, window funcs, CTEs, unions, subqueries.
# Run with: uv run dbt run --select "tag:minimal" --vars '{"sf":"1"}'
# NOTE: these models are excluded from DAG edge injection so they always work
# standalone without needing a prior full run.
MINIMAL_MODELS = {
    # views, 0-join
    "oi_full_scan",             # view, scan:orders_items, 0 joins, no agg, 6M rows, no filter
    "oi_filter_recent_90d",     # view, filtered scan, light filter
    "oi_filter_tiny_orders",    # view, heavy filter
    "oi_agg_by_month",          # view, simple agg
    "oi_win_rank_by_customer",  # view, window func
    "oi_win_running_total",     # view, window (running total)
    "ord_full_scan",            # view, scan:orders, smaller table
    "cust_full_scan",           # view, scan:customers, 150K
    "supp_full_scan",           # view, scan:suppliers, 10K
    "distinct_ship_modes",      # view, distinct, tiny output
    "top100_orders_by_amount",  # view, order by + limit
    "case_shipping_speed",      # view, case expression
    # views, joins
    "join_orders_customers",    # view, 1 join, no agg
    "join_oi_parts_agg_brand",  # view, 1 join, simple agg
    "join3_oi_cust_nat",        # view, 2 joins
    "join4_oi_cust_nat_reg",    # view, 3 joins
    "join5_oi_parts_supp_nat_reg",  # view, 4 joins
    # views, complex patterns
    "cte_top_customers",        # view, CTE + join + filter
    "cte_monthly_trend",        # view, CTE + window (multi agg)
    "union_ship_modes",         # view, union all
    "customers_without_orders", # view, NOT EXISTS subquery
    "having_big_customers",     # view, HAVING clause
    # tables (CTAS write path)
    "tbl_oi_full",              # table, full scan write
    "tbl_oi_agg_customer",      # table, agg write
    "tbl_join_ord_cust",        # table, join write
    "tbl_join3_oi_parts_supp",  # table, 2-join write
    "tbl_cte_supplier_ranking", # table, CTE + window write
}


# === Wrap up: add SF-encoding comment to every model ===
# This ensures different SF values produce different query text → different hashes

def write_model(name, sql, materialized, tags):
    """Write a single model file with SF-encoding comment."""
    if name in MINIMAL_MODELS:
        tags = tags + ["minimal"]
    full_sql = model_sql(sql, materialized, tags)
    # Encode SF in a comment so SF1 and SF10 produce different query hashes
    full_sql += "\n-- sf={{ var('sf', '10') }}\n"
    filepath = os.path.join(OUTPUT_DIR, f"{name}.sql")
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "w") as f:
        f.write(full_sql)


def parse_args():
    parser = argparse.ArgumentParser(description="Generate dbt models for benchmarking")
    parser.add_argument("--seed", type=int, default=42, help="Random seed (default: 42)")
    parser.add_argument("--p-source", type=float, default=0.25,
                        help="Probability of Type A edge — source substitution (default: 0.25)")
    parser.add_argument("--p-dep", type=float, default=0.35,
                        help="Probability of Type B edge — existence dependency (default: 0.35)")
    parser.add_argument("--no-dag", action="store_true",
                        help="Skip DAG construction (flat fan-out, original behavior)")
    parser.add_argument("--no-incremental", action="store_true",
                        help="Skip incremental conversion")
    return parser.parse_args()


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    args = parse_args()

    # Check for duplicate names
    names = [m[0] for m in models]
    dupes = [n for n in names if names.count(n) > 1]
    if dupes:
        print(f"ERROR: duplicate model names: {set(dupes)}")
        exit(1)

    final_models = list(models)
    edges = {}

    if not args.no_dag:
        from dag_builder import build_dag, convert_to_incremental, generate_mermaid

        # Split minimal models out — they don't get DAG edges
        minimal_indices = {i for i, (n, _, _, _) in enumerate(final_models) if n in MINIMAL_MODELS}
        dag_models = [m for i, m in enumerate(final_models) if i not in minimal_indices]
        kept_models = [(i, m) for i, m in enumerate(final_models) if i in minimal_indices]

        # Build full_scan_map: ODS table -> [full_scan model names]
        # These are always safe as Type A upstreams (all columns, no filter)
        full_scan_map = {}
        for name, sql, mat, tags in final_models:
            if name.endswith("_full_scan"):
                for t in tags:
                    if t.startswith("scan:") and "+" not in t:
                        table = t.replace("scan:", "")
                        full_scan_map.setdefault(table, []).append(name)

        # Build DAG on non-minimal models
        dag_models, edges = build_dag(dag_models, seed=args.seed,
                                      p_source=args.p_source, p_dep=args.p_dep,
                                      full_scan_map=full_scan_map)

        if not args.no_incremental:
            dag_models = convert_to_incremental(dag_models, seed=args.seed)

        # Merge back: put minimal models in their original positions
        final_models = []
        dag_iter = iter(dag_models)
        kept_dict = dict(kept_models)
        for i in range(len(models)):
            if i in kept_dict:
                final_models.append(kept_dict[i])
            else:
                final_models.append(next(dag_iter))

        # Generate mermaid diagram
        mermaid_path = os.path.join(OUTPUT_DIR, "DAG.md")
        generate_mermaid(edges, mermaid_path)
        print(f"DAG diagram written to {mermaid_path}")

    # Idempotent: wipe and recreate
    if os.path.exists(OUTPUT_DIR):
        shutil.rmtree(OUTPUT_DIR)
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    if not args.no_dag:
        # Re-generate mermaid after wipe
        from dag_builder import generate_mermaid
        mermaid_path = os.path.join(OUTPUT_DIR, "DAG.md")
        generate_mermaid(edges, mermaid_path)

    for name, sql, materialized, tags in final_models:
        write_model(name, sql, materialized, tags)

    # Stats
    table_count = sum(1 for _, _, m, _ in final_models if m == "table")
    view_count = sum(1 for _, _, m, _ in final_models if m == "view")
    inc_count = sum(1 for _, _, m, _ in final_models if m == "incremental")
    print(f"Generated {len(final_models)} models ({table_count} tables, {view_count} views, {inc_count} incremental) in {OUTPUT_DIR}")

    if edges:
        edge_count = sum(len(v) for v in edges.values())
        models_with_edges = sum(1 for v in edges.values() if v)
        print(f"DAG: {models_with_edges} models with upstream edges, {edge_count} edges total")

    # Tag distribution
    from collections import Counter
    join_counts = Counter()
    agg_counts = Counter()
    for _, _, _, tags in final_models:
        for t in tags:
            if t.startswith("joins:"):
                join_counts[t] += 1
            if t.startswith("agg:"):
                agg_counts[t] += 1
    print(f"Join distribution: {dict(join_counts)}")
    print(f"Agg distribution: {dict(agg_counts)}")

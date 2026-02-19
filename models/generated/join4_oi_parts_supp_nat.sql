{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts+suppliers+nations', 'joins:3', 'agg:none', 'rows_sf1:6M', 'cols:8', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_cust_agg_segment') }} limit 1)

select
    oi.order_item_key, oi.order_date,
    oi.gross_item_sales_amount, oi.quantity,
    p.part_brand_name, p.part_type_name,
    s.supplier_name,
    n.nation_name
from {{ ref('tbl_oi_returned') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
join {{ ref('suppliers') }} s on oi.supplier_key = s.supplier_key
join {{ ref('nations') }} n on s.nation_key = n.nation_key

-- sf={{ var('sf', '10') }}

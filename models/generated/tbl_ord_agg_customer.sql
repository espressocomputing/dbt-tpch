{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:150K', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand12_1993') }} limit 1)

select customer_key, count(*) as order_count, sum(order_amount) as total_spent, min(order_date) as first_order, max(order_date) as last_order
from {{ ref('ord_full_scan') }}
group by customer_key

-- sf={{ var('sf', '10') }}

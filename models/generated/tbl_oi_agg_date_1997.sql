{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:100K', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('oi_ship_reg_air_reg_middle_east') }} limit 1)

select
    customer_key,
    count(*) as item_count,
    sum(gross_item_sales_amount) as total_sales,
    sum(quantity) as total_qty
from {{ ref('orders_items') }}
where order_date >= '1997-01-01' and order_date <= '1997-12-31'
group by 1

) _q
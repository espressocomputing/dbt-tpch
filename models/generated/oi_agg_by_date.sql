{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:2500', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_join_oi_cust_reg_europe') }} limit 1)

select
    order_date as group_key,
    count(*) as cnt, sum(gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }}
group by 1

) _q
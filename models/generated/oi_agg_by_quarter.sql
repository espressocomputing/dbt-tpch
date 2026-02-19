{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:28', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    date_trunc('quarter', order_date) as group_key,
    count(*) as cnt, sum(gross_item_sales_amount) as total_sales, sum(net_item_sales_amount) as total_net
from {{ ref('orders_items') }}
group by 1

) _q
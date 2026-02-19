{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items+customers+nations', 'joins:2', 'agg:simple', 'rows_sf1:25', 'cols:3', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    n.nation_name,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1

-- sf={{ var('sf', '10') }}

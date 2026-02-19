{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers+nations', 'joins:2', 'agg:simple', 'rows_sf1:2100', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    n.nation_name,
    date_trunc('month', o.order_date) as month,
    count(*) as order_count,
    sum(o.order_amount) as total_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1, 2

-- sf={{ var('sf', '10') }}

{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:1', 'agg:none', 'rows_sf1:500K', 'cols:6', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

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

-- sf={{ var('sf', '10') }}

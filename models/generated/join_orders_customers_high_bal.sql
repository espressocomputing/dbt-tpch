{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:150K', 'cols:5', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_account_balance
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where c.customer_account_balance > 9000

-- sf={{ var('sf', '10') }}

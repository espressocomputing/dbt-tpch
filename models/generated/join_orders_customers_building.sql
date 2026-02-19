{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:300K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_h1_1994_fob') }} limit 1)

select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_account_balance
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where c.customer_market_segment_name = 'BUILDING'

-- sf={{ var('sf', '10') }}

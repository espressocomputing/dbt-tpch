{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:60K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_ship_reg_air_reg_middle_east') }} limit 1)

select
    o.order_key, o.order_date, o.order_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where o.order_priority_code = '4-NOT SPECIFIED'
    and c.customer_market_segment_name = 'AUTOMOBILE'

-- sf={{ var('sf', '10') }}

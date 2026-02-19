{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:60K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    o.order_key, o.order_date, o.order_amount
from {{ ref('ord_filter_open') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where o.order_priority_code = '1-URGENT'
    and c.customer_market_segment_name = 'AUTOMOBILE'

-- sf={{ var('sf', '10') }}

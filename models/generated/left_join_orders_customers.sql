{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:1.5M', 'cols:5', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('ord_prio_4_not_specified_seg_furniture') }} limit 1)

select
    o.order_key, o.order_date, o.order_amount,
    c.customer_name, c.customer_market_segment_name
from {{ ref('orders') }} o
left join {{ ref('customers') }} c on o.customer_key = c.customer_key

-- sf={{ var('sf', '10') }}

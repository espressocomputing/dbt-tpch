{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers+orders', 'joins:1', 'agg:none', 'rows_sf1:100K', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_brand_brand21_1996') }} limit 1)

select c.customer_key, c.customer_name, c.customer_market_segment_name
from {{ ref('customers') }} c
where exists (
    select 1 from {{ ref('orders') }} o where o.customer_key = c.customer_key
)

-- sf={{ var('sf', '10') }}

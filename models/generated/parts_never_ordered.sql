{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts+orders_items', 'joins:1', 'agg:none', 'rows_sf1:1K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select p.part_key, p.part_name, p.part_brand_name, p.retail_price
from {{ ref('parts') }} p
where not exists (
    select 1 from {{ ref('orders_items') }} oi where oi.part_key = p.part_key
)

-- sf={{ var('sf', '10') }}

{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:7', 'cols:1', 'filter:none', 'sample', 'sf' ~ var('sf', '10')]
    )
}}

select distinct ship_mode_name from {{ ref('orders_items') }}

-- sf={{ var('sf', '10') }}

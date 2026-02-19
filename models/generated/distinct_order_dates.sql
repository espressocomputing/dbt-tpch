{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:2500', 'cols:1', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select distinct order_date from {{ ref('orders') }} order by 1

-- sf={{ var('sf', '10') }}

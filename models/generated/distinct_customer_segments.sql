{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers', 'joins:0', 'agg:none', 'rows_sf1:5', 'cols:1', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select distinct customer_market_segment_name from {{ ref('customers') }}

-- sf={{ var('sf', '10') }}

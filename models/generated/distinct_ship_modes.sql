{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:none', 'rows_sf1:7', 'cols:1', 'filter:none', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select distinct ship_mode_name from {{ ref('orders_items') }}

) _q
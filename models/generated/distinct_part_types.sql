{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts', 'joins:0', 'agg:none', 'rows_sf1:150', 'cols:1', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select distinct part_type_name from {{ ref('parts_filter_brass') }}

-- sf={{ var('sf', '10') }}

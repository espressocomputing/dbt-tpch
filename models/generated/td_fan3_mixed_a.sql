{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_fan3_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select * from {{ ref('td_fan3_mixed_root') }} where total_sales > 50000

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_diamond10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select * from {{ ref('td_diamond10_mixed_src') }} where order_date > '1995-01-01'

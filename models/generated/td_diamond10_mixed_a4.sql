{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_diamond10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select customer_key, count(*) as cnt from {{ ref('td_diamond10_mixed_src') }} group by 1

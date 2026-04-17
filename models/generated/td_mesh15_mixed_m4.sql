{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select customer_key, count(*) as cnt from {{ ref('td_mesh15_mixed_s3') }} group by 1

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select a.* from {{ ref('td_mesh15_mixed_s1') }} a
join {{ ref('td_mesh15_mixed_s2') }} b on a.customer_key = b.customer_key

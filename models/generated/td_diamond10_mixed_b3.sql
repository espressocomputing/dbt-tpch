{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_diamond10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select a.* from {{ ref('td_diamond10_mixed_a3') }} a join {{ ref('td_diamond10_mixed_a4') }} b on a.customer_key = b.customer_key

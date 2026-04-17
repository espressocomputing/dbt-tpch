{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select order_key, items * 2 as doubled from {{ ref('td_tree10_mixed_l1b') }}

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_mesh15_mixed', 'sf' ~ var('sf', '10')]
    )
}}

select 'td_mesh15_mixed_m7' as src, count(*) as n from {{ ref('td_mesh15_mixed_m7') }}
union all
select 'td_mesh15_mixed_m8' as src, count(*) as n from {{ ref('td_mesh15_mixed_m8') }}
union all
select 'td_mesh15_mixed_m9' as src, count(*) as n from {{ ref('td_mesh15_mixed_m9') }}

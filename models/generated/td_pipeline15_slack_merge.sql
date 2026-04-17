{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select 'a' as chain, count(*) as n from {{ ref('td_pipeline15_slack_a5') }}
union all
select 'b', count(*) from {{ ref('td_pipeline15_slack_b5') }}
union all
select 'c', count(*) from {{ ref('td_pipeline15_slack_c4') }}
) _q
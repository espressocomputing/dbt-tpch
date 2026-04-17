{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select a.* from {{ ref('td_chain10_slack_n03') }} a
join {{ ref('td_chain10_slack_n04') }} b on a.customer_key = b.customer_key
) _q
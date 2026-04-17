{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select a.cnt as cnt_a, a.src, 'td_layered100_slack_j06' as _node from {{ ref('td_layered100_slack_a11') }} a
cross join {{ ref('td_layered100_slack_a07') }} b
cross join {{ ref('td_layered100_slack_a04') }} c

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select a.cnt as cnt_a, a.src, 'td_layered100_slack_j09' as _node from {{ ref('td_layered100_slack_a21') }} a
cross join {{ ref('td_layered100_slack_a13') }} b

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select count(*) as final_cnt, 'td_layered100_slack_k04' as _node from {{ ref('td_layered100_slack_j24') }}

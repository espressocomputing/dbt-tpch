{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select cnt, _node as src, 'td_layered100_slack_a21' as _node from {{ ref('td_layered100_slack_t24') }}

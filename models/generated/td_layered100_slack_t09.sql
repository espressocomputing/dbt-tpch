{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select count(*) as cnt, 'td_layered100_slack_t09' as _node from {{ ref('td_layered100_slack_s02') }}

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select count(*) as cnt from {{ ref('td_chain10_slack_n07') }}

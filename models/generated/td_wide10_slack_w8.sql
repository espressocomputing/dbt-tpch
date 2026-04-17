{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select avg(avg_discount) as mean_discount from {{ ref('td_wide10_slack_src') }}

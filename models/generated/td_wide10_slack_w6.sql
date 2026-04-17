{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select max(total_sales) as max_sales from {{ ref('td_wide10_slack_src') }}

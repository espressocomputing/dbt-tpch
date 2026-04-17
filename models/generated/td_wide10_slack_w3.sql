{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select * from {{ ref('td_wide10_slack_src') }} where total_sales > 50000

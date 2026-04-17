{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select min(total_sales) as min_sales from {{ ref('td_wide10_slack_src') }}

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}

select * from {{ ref('td_pipeline15_slack_b2') }} where order_count > 5

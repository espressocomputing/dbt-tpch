{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select * from {{ ref('td_chain10_slack_n06') }} where row_count > 5

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}


select a.*, c.customer_name from {{ ref('td_pipeline15_slack_a2') }} a
join {{ ref('customers') }} c on a.customer_key = c.customer_key

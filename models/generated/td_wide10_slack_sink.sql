{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_wide10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select 'td_wide10_slack_w1' as src, count(*) as n from {{ ref('td_wide10_slack_w1') }}
union all
select 'td_wide10_slack_w2' as src, count(*) as n from {{ ref('td_wide10_slack_w2') }}
union all
select 'td_wide10_slack_w3' as src, count(*) as n from {{ ref('td_wide10_slack_w3') }}
union all
select 'td_wide10_slack_w4' as src, count(*) as n from {{ ref('td_wide10_slack_w4') }}
union all
select 'td_wide10_slack_w5' as src, count(*) as n from {{ ref('td_wide10_slack_w5') }}
union all
select 'td_wide10_slack_w6' as src, count(*) as n from {{ ref('td_wide10_slack_w6') }}
union all
select 'td_wide10_slack_w7' as src, count(*) as n from {{ ref('td_wide10_slack_w7') }}
union all
select 'td_wide10_slack_w8' as src, count(*) as n from {{ ref('td_wide10_slack_w8') }}

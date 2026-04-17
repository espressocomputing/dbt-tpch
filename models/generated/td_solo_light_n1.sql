{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_solo_light', 'sf' ~ var('sf', '10')]
    )
}}


select * from {{ ref('nations') }}

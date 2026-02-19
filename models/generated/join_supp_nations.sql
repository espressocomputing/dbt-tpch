{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:suppliers+nations', 'joins:1', 'agg:none', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_oi_win_rank_customer') }} limit 1)

select
    s.supplier_key, s.supplier_name, s.supplier_account_balance,
    n.nation_name
from {{ ref('supp_full_scan') }} s
join {{ ref('nations') }} n on s.nation_key = n.nation_key

) _q
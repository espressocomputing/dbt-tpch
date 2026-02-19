{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:parts_suppliers', 'joins:0', 'agg:none', 'rows_sf1:800K', 'cols:9', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('join_oi_reg_africa_agg_1993') }} limit 1)

select
    part_supplier_key, part_key, part_name, part_brand_name,
    supplier_key, supplier_name, nation_key,
    supplier_availabe_quantity, supplier_cost_amount
from {{ ref('parts_suppliers') }}

-- sf={{ var('sf', '10') }}

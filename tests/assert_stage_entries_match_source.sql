-- every stage_id change in the source must produce exactly one stage entry
with source_count as (

    select count(*) as n
    from {{ ref('prep_pipedrive__deal_changes') }}
    where changed_field_key = 'stage_id'

),

model_count as (

    select count(*) as n
    from {{ ref('int_crm__deal_stage_entries') }}

)

select
    source_count.n as source_rows,
    model_count.n as model_rows
from source_count
cross join model_count
where source_count.n != model_count.n

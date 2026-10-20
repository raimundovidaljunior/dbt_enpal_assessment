-- an inferred stage must lie below the stage the deal actually reached
select *
from {{ ref('int_crm__deal_stage_entries_inferred') }}
where stage_id >= reached_stage_id

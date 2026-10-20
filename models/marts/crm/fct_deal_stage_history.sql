with deal_stage_entries as (

    select * from {{ ref('int_crm__deal_stage_entries') }}

),

with_exits as (

    select
        deal_stage_entry_id,
        deal_id,
        stage_id,
        stage_name,
        previous_stage_id,
        lead(stage_id) over (partition by deal_id order by entered_at) as next_stage_id,
        entered_at,
        lead(entered_at) over (partition by deal_id order by entered_at) as exited_at
    from deal_stage_entries

)

select
    deal_stage_entry_id,
    deal_id,
    stage_id,
    stage_name,
    previous_stage_id,
    next_stage_id,
    entered_at,
    exited_at,
    exited_at::date - entered_at::date as days_in_stage,
    exited_at is null as is_current_stage
from with_exits

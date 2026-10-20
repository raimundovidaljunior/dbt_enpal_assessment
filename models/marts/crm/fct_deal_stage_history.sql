with deal_stage_entries as (

    select * from {{ ref('int_crm__deal_stage_entries') }}

),

stages as (

    select * from {{ ref('prep_pipedrive__stages') }}

),

with_exits as (

    select
        deal_stage_entries.deal_stage_entry_id,
        deal_stage_entries.deal_id,
        deal_stage_entries.stage_id,
        stages.stage_name,
        deal_stage_entries.previous_stage_id,
        lead(deal_stage_entries.stage_id) over (
            partition by deal_stage_entries.deal_id
            order by deal_stage_entries.entered_at
        ) as next_stage_id,
        deal_stage_entries.entered_at,
        lead(deal_stage_entries.entered_at) over (
            partition by deal_stage_entries.deal_id
            order by deal_stage_entries.entered_at
        ) as exited_at
    from deal_stage_entries
    left join stages
        on deal_stage_entries.stage_id = stages.stage_id

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

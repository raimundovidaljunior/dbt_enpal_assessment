with deal_current_state as (

    select * from {{ ref('int_crm__deal_current_state') }}

),

deal_stage_entries as (

    select * from {{ ref('int_crm__deal_stage_entries') }}

),

deal_stage_entries_inferred as (

    select * from {{ ref('int_crm__deal_stage_entries_inferred') }}

),

lost_reasons as (

    select * from {{ ref('prep_pipedrive__lost_reasons') }}

),

stage_summary as (

    select
        deal_id,
        max(stage_id) as max_stage_id,
        count(distinct stage_id) as stages_entered_count,
        min(entered_at) as first_stage_entered_at,
        max(entered_at) as last_stage_entered_at
    from deal_stage_entries
    group by deal_id

),

skipped_summary as (

    select
        deal_id,
        count(distinct stage_id) as stages_skipped_count
    from deal_stage_entries_inferred
    group by deal_id

),

final as (

    select
        deal_current_state.deal_id,
        deal_current_state.created_at,
        deal_current_state.owner_user_id,
        deal_current_state.owner_changes_count,
        deal_current_state.current_stage_id,
        stage_summary.max_stage_id,
        stage_summary.stages_entered_count,
        coalesce(skipped_summary.stages_skipped_count, 0) as stages_skipped_count,
        stage_summary.first_stage_entered_at,
        stage_summary.last_stage_entered_at,
        deal_current_state.lost_at,
        deal_current_state.lost_reason_id,
        lost_reasons.lost_reason_name,
        deal_current_state.lost_at::date - deal_current_state.created_at::date as deal_duration_days,
        deal_current_state.creations_count > 1 as has_multiple_creations
    from deal_current_state
    left join stage_summary
        on deal_current_state.deal_id = stage_summary.deal_id
    left join skipped_summary
        on deal_current_state.deal_id = skipped_summary.deal_id
    left join lost_reasons
        on deal_current_state.lost_reason_id = lost_reasons.lost_reason_id

)

select * from final

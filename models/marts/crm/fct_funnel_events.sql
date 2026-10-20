-- one row per funnel event: actual stage entries, inferred (skipped) stage entries and sales calls
with funnel_steps as (

    select * from {{ ref('funnel_steps') }}

),

deal_stage_entries as (

    select * from {{ ref('int_crm__deal_stage_entries') }}

),

deal_stage_entries_inferred as (

    select * from {{ ref('int_crm__deal_stage_entries_inferred') }}

),

sales_calls as (

    select * from {{ ref('int_crm__sales_calls') }}

),

stage_events as (

    select
        deal_stage_entries.deal_stage_entry_id as funnel_event_id,
        deal_stage_entries.deal_id,
        funnel_steps.funnel_step,
        funnel_steps.kpi_name,
        funnel_steps.sort_order,
        deal_stage_entries.entered_at as event_at,
        'stage' as event_source,
        false as is_inferred,
        true as is_done
    from deal_stage_entries
    inner join funnel_steps
        on funnel_steps.source_type = 'stage'
        and funnel_steps.source_value = deal_stage_entries.stage_id::text

),

inferred_stage_events as (

    select
        deal_stage_entries_inferred.deal_stage_entry_id as funnel_event_id,
        deal_stage_entries_inferred.deal_id,
        funnel_steps.funnel_step,
        funnel_steps.kpi_name,
        funnel_steps.sort_order,
        deal_stage_entries_inferred.entered_at as event_at,
        'stage' as event_source,
        true as is_inferred,
        true as is_done
    from deal_stage_entries_inferred
    inner join funnel_steps
        on funnel_steps.source_type = 'stage'
        and funnel_steps.source_value = deal_stage_entries_inferred.stage_id::text

),

activity_events as (

    select
        sales_calls.sales_call_id as funnel_event_id,
        sales_calls.deal_id,
        funnel_steps.funnel_step,
        funnel_steps.kpi_name,
        funnel_steps.sort_order,
        sales_calls.due_at as event_at,
        'activity' as event_source,
        false as is_inferred,
        sales_calls.is_done
    from sales_calls
    inner join funnel_steps
        on funnel_steps.source_type = 'activity'
        and funnel_steps.source_value = sales_calls.activity_type

),

final as (

    select * from stage_events
    union all
    select * from inferred_stage_events
    union all
    select * from activity_events

)

select * from final

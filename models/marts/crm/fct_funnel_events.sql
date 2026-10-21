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

-- events keyed like the seed (source_type, source_value), so it is joined once. source_value
-- mixes stage ids and activity codes, so stage ids are cast to text for this join only
events as (

    select
        deal_stage_entry_id as funnel_event_id,
        deal_id,
        'stage' as source_type,
        stage_id::text as source_value,
        entered_at as event_at,
        false as is_inferred,
        true as is_done
    from deal_stage_entries

    union all

    select
        deal_stage_entry_id as funnel_event_id,
        deal_id,
        'stage' as source_type,
        stage_id::text as source_value,
        entered_at as event_at,
        true as is_inferred,
        true as is_done
    from deal_stage_entries_inferred

    union all

    select
        sales_call_id as funnel_event_id,
        deal_id,
        'activity' as source_type,
        activity_type as source_value,
        due_at as event_at,
        false as is_inferred,
        is_done
    from sales_calls

),

final as (

    select
        events.funnel_event_id,
        events.deal_id,
        funnel_steps.funnel_step,
        funnel_steps.kpi_name,
        funnel_steps.sort_order,
        events.event_at,
        events.source_type as event_source,
        events.is_inferred,
        events.is_done
    from events
    inner join funnel_steps
        on events.source_type = funnel_steps.source_type
        and events.source_value = funnel_steps.source_value

)

select * from final

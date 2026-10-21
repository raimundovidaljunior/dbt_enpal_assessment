with deal_changes as (

    select * from {{ ref('prep_pipedrive__deal_changes') }}

),

-- deal_changes is an event log; new_value is text whose meaning depends on changed_field_key,
-- so it is only cast to a stage id for stage_id changes
stage_entries as (

    select
        deal_id,
        new_value::int as stage_id,
        changed_at as entered_at
    from deal_changes
    where changed_field_key = 'stage_id'

),

final as (

    select
        md5(concat_ws(
            '-', stage_entries.deal_id, stage_entries.stage_id, stage_entries.entered_at
        )) as deal_stage_entry_id,
        stage_entries.deal_id,
        stage_entries.stage_id,
        -- previous stage in time order. known limitation: the 5 deal_ids with two creations run
        -- two lifecycles in parallel, so their previous stage can come from the other lifecycle
        lag(stage_entries.stage_id) over (
            partition by stage_entries.deal_id
            order by stage_entries.entered_at
        ) as previous_stage_id,
        stage_entries.entered_at
    from stage_entries

)

select * from final

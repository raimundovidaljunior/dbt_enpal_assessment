with deal_changes as (

    select * from {{ ref('prep_pipedrive__deal_changes') }}

),

stages as (

    select * from {{ ref('prep_pipedrive__stages') }}

),

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
        stages.stage_name,
        lag(stage_entries.stage_id) over (
            partition by stage_entries.deal_id
            order by stage_entries.entered_at
        ) as previous_stage_id,
        stage_entries.entered_at
    from stage_entries
    left join stages
        on stage_entries.stage_id = stages.stage_id

)

select * from final

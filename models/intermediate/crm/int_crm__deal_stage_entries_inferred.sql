-- skipped stages are counted as entered when a deal moves past them (Pipedrive Insights convention)
with deal_stage_entries as (

    select * from {{ ref('int_crm__deal_stage_entries') }}

),

stages as (

    select * from {{ ref('prep_pipedrive__stages') }}

),

skipped_stages as (

    select
        deal_id,
        generate_series(previous_stage_id + 1, stage_id - 1) as stage_id,
        stage_id as reached_stage_id,
        entered_at
    from deal_stage_entries
    where stage_id > previous_stage_id + 1

),

final as (

    select
        md5(concat_ws(
            '-', skipped_stages.deal_id, skipped_stages.stage_id, skipped_stages.entered_at, 'inferred'
        )) as deal_stage_entry_id,
        skipped_stages.deal_id,
        skipped_stages.stage_id,
        stages.stage_name,
        skipped_stages.reached_stage_id,
        skipped_stages.entered_at
    from skipped_stages
    left join stages
        on skipped_stages.stage_id = stages.stage_id

)

select * from final

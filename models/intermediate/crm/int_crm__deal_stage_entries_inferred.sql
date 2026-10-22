-- skipped stages are counted as entered when a deal moves past them (Pipedrive Insights convention).
-- example: a deal moving 1 -> 4 gets inferred rows for stages 2 and 3, both timestamped at the
-- entry into 4. only these generated rows live here; actual entries are in
-- int_crm__deal_stage_entries, and fct_funnel_events unions both.
-- assumption: stage_id order is the pipeline order. pipedrive orders stages by order_nr, which
-- is not in this export, and stage ids 1-9 follow the README funnel.
with deal_stage_entries as (

    select * from {{ ref('int_crm__deal_stage_entries') }}

),

skipped_stages as (

    select
        deal_id,
        -- one row per stage strictly between the previous and the reached stage
        generate_series(previous_stage_id + 1, stage_id - 1) as stage_id,
        stage_id as reached_stage_id,
        -- skipped stages have no time of their own, so they take the time the deal reached
        -- the later stage
        entered_at
    from deal_stage_entries
    -- only forward jumps of more than one stage; adjacent, backward and same-stage moves and
    -- first entries (previous_stage_id is null) produce nothing
    where stage_id > previous_stage_id + 1

),

final as (

    select
        md5(concat_ws(
            '-', skipped_stages.deal_id, skipped_stages.stage_id, skipped_stages.entered_at, 'inferred'
        )) as deal_stage_entry_id,
        skipped_stages.deal_id,
        skipped_stages.stage_id,
        skipped_stages.reached_stage_id,
        skipped_stages.entered_at
    from skipped_stages

)

select * from final

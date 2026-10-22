-- Question: how do deals move through the pipeline stages?
-- Findings:
--   All 1,995 deals start at stage 1 (Lead Generation).
--   1,684 deals (84.4%) skip at least one stage (e.g. 1>2>4). The most common paths are
--   1>2>3>4 (82) and 1>2>3>4>5 (76).
--   Moves are almost always forward: 8 backward moves and 2 same-stage repeats in total.
--   Consequence: counting only recorded stage entries under-counts the middle of the funnel;
--   skipped stages are backfilled (Pipedrive Insights convention) in
--   int_crm__deal_stage_entries_inferred, flagged with is_inferred.

with stage_changes as (

    select
        deal_id,
        new_value::int as stage_id,
        change_time,
        lag(new_value::int) over (partition by deal_id order by change_time) as previous_stage_id
    from {{ source('postgres_public', 'deal_changes') }}
    where changed_field_key = 'stage_id'

),

per_deal as (

    select
        deal_id,
        string_agg(stage_id::text, '>' order by change_time) as stage_path,
        (array_agg(stage_id order by change_time))[1] as first_stage_id,
        count(*) filter (where stage_id > previous_stage_id + 1) as forward_skips,
        count(*) filter (where stage_id < previous_stage_id) as backward_moves,
        count(*) filter (where stage_id = previous_stage_id) as same_stage_repeats
    from stage_changes
    group by deal_id

)

select
    'summary' as section,
    null as stage_path,
    count(*) as deals,
    count(*) filter (where first_stage_id = 1) as deals_starting_at_stage_1,
    count(*) filter (where forward_skips > 0) as deals_with_skips,
    round(100.0 * count(*) filter (where forward_skips > 0) / count(*), 1) as pct_deals_with_skips,
    sum(backward_moves) as backward_moves,
    sum(same_stage_repeats) as same_stage_repeats
from per_deal

union all

select * from (
    select
        'top path' as section,
        stage_path,
        count(*) as deals,
        null::bigint, null::bigint, null::numeric, null::numeric, null::numeric
    from per_deal
    group by stage_path
    order by count(*) desc
    limit 10
) as top_paths

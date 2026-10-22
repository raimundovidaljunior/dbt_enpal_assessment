-- Question: how much of each funnel stage was actually recorded, and how much comes from the
-- skipped-stage backfill?
-- Findings:
--   No deal has all 9 stages recorded; deals record 4.5 stage entries on average.
--   About half of the deals reaching the middle of the funnel never had that stage recorded:
--   Negotiation 53% recorded (894 of 1,693), Closing 52% (741 of 1,424), Implementation/Onboarding
--   54% (588 of 1,081). Stages 1 and 9 are fully recorded, since nothing can be skipped before 1
--   or after 9.
--   Consequence: the backfilled funnel is monotonic, but the recorded stage log is not; the skip
--   rate itself is worth raising with sales ops (optional stages, an incomplete log, or cards moved
--   several stages at once).
-- "Reached" = the deal's highest stage is at or beyond the stage. Every deal starts at stage 1,
-- so this equals the backfilled count in fct_funnel_events.
with stage_changes as (

    select
        deal_id,
        new_value::int as stage_id
    from {{ source('postgres_public', 'deal_changes') }}
    where changed_field_key = 'stage_id'

),

per_deal as (

    select
        deal_id,
        max(stage_id) as max_stage_id,
        count(distinct stage_id) as distinct_stages_recorded,
        count(*) as stage_entries
    from stage_changes
    group by deal_id

),

stages as (

    select generate_series(1, 9) as stage_id

),

per_stage as (

    select
        stages.stage_id,
        count(distinct per_deal.deal_id) as deals_reached,
        count(distinct stage_changes.deal_id) as deals_recorded
    from stages
    left join per_deal
        on per_deal.max_stage_id >= stages.stage_id
    left join stage_changes
        on stage_changes.deal_id = per_deal.deal_id
        and stage_changes.stage_id = stages.stage_id
    group by stages.stage_id

)

select
    stage_id::text as stage,
    deals_reached,
    deals_recorded,
    round(100.0 * deals_recorded / deals_reached, 1) as pct_recorded,
    null::numeric as avg_stage_entries
from per_stage

union all

select
    'all 9 recorded',
    count(*),
    count(*) filter (where distinct_stages_recorded = 9),
    round(100.0 * count(*) filter (where distinct_stages_recorded = 9) / count(*), 1),
    round(avg(stage_entries), 1)
from per_deal

order by stage

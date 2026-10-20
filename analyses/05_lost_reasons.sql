-- Question: can lost_reason be used to separate won from lost deals?
-- Findings:
--   No. Every deal has a lost_reason, including the 324 deals that reached stage 9
--   (Renewal/Expansion), and it is always set after the last stage change.
--   Consequence: lost_reason marks the end of a deal, not an outcome,
--   and does not remove deals from the funnel.

with deal_changes as (

    select * from {{ source('postgres_public', 'deal_changes') }}

),

per_deal as (

    select
        deal_id,
        max(new_value::int) filter (where changed_field_key = 'stage_id') as max_stage_id,
        max(change_time) filter (where changed_field_key = 'lost_reason') as lost_at,
        max(change_time) filter (where changed_field_key = 'stage_id') as last_stage_at
    from deal_changes
    group by deal_id

)

select
    max_stage_id,
    count(*) as deals,
    count(lost_at) as deals_with_lost_reason,
    count(*) filter (where lost_at >= last_stage_at) as lost_after_last_stage_change
from per_deal
group by max_stage_id
order by max_stage_id

-- Question: which deal fields does the change log track, and how often?
-- Findings:
--   Four field keys only: stage_id (8,906), user_id (2,500), add_time (2,000), lost_reason (2,000).
--   Every deal has every field. add_time and lost_reason occur at most twice per deal
--   (the 1,995 deals have 2,000 add_time events, see 04_reused_deal_ids).
--   deal_changes is an event log, so deal state (owner, stage, lost reason) must be rebuilt
--   from the latest event per field; the funnel only needs the stage_id events.

with deal_changes as (

    select * from {{ source('postgres_public', 'deal_changes') }}

),

per_deal_field as (

    select
        deal_id,
        changed_field_key,
        count(*) as events
    from deal_changes
    group by deal_id, changed_field_key

)

select
    deal_changes.changed_field_key,
    count(*) as row_count,
    count(distinct deal_changes.deal_id) as deals,
    min(deal_changes.change_time) as min_at,
    max(deal_changes.change_time) as max_at,
    (
        select max(events)
        from per_deal_field
        where per_deal_field.changed_field_key = deal_changes.changed_field_key
    ) as max_events_per_deal
from deal_changes
group by deal_changes.changed_field_key
order by row_count desc

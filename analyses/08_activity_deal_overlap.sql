-- Question: are the few activity deal_ids that exist in deal_changes real links, or chance?
-- Findings:
--   Both tables draw 6-digit deal_ids from the same range (~100000-999999). With 4,572 activity
--   ids and 1,995 deal ids, random overlap alone would give ~10 matches; there are 8.
--   The 8 matches are also inconsistent: 4 calls are due before the deal was created and 1
--   meeting is due after the deal was lost. Almost every activity deal_id has exactly one
--   activity, so no deal shows Sales Call 1 followed by Sales Call 2.
--   Consequence: activity deal_ids are effectively unrelated to the deals. Steps 2.1 and 3.1
--   count sales calls by due month (each call carries its own deal_id), not deals of the
--   stage funnel. The id mapping is an open question for the data owner.
with activity as (

    select * from {{ source('postgres_public', 'activity') }}

),

deal_changes as (

    select * from {{ source('postgres_public', 'deal_changes') }}

),

deals as (

    select
        deal_id,
        min(change_time) filter (where changed_field_key = 'add_time') as deal_created_at,
        max(change_time) filter (where changed_field_key = 'lost_reason') as deal_lost_at
    from deal_changes
    group by deal_id

),

id_space as (

    select
        (select count(distinct deal_id) from activity) as activity_deal_ids,
        (select count(*) from deals) as deal_ids,
        least((select min(deal_id) from activity), (select min(deal_id) from deals)) as min_id,
        greatest((select max(deal_id) from activity), (select max(deal_id) from deals)) as max_id

),

matches as (

    select
        activity.deal_id,
        activity.type as activity_type,
        activity.due_to as due_at,
        deals.deal_created_at,
        deals.deal_lost_at
    from activity
    inner join deals
        on activity.deal_id = deals.deal_id

)

select
    'chance' as section,
    null::int as deal_id,
    null as activity_type,
    null::timestamp as due_at,
    null::timestamp as deal_created_at,
    null::timestamp as deal_lost_at,
    null as timing,
    (select count(distinct deal_id) from matches) as observed_matches,
    round(activity_deal_ids * deal_ids / (max_id - min_id + 1.0), 1) as expected_random_matches
from id_space

union all

select
    'match',
    deal_id,
    activity_type,
    due_at,
    deal_created_at,
    deal_lost_at,
    case
        when due_at < deal_created_at then 'due before deal created'
        when due_at > deal_lost_at then 'due after deal lost'
        else 'within deal lifetime'
    end,
    null,
    null
from matches
order by section, deal_id

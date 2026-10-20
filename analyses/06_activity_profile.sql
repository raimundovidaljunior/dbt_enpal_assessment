-- Question: can activities (sales calls) be linked to deals, and are they reliable?
-- Findings:
--   Four types with ~1,130-1,180 rows each; about 50% are done.
--   Only 8 of the 4,572 activity deal_ids exist in deal_changes, so activities cannot be
--   joined to the deal pipeline. They are effectively a separate population.
--   11 activity_ids appear twice with different attributes, so activity_id is not a key.
--   Consequence: Sales Call 1 (meeting) and Sales Call 2 (sc_2) are counted on their own
--   from activity, by due_to month, done or not; int_crm__sales_calls adds a surrogate key.

with activity as (

    select * from {{ source('postgres_public', 'activity') }}

),

deal_ids as (

    select distinct deal_id from {{ source('postgres_public', 'deal_changes') }}

),

duplicated_ids as (

    select activity_id
    from activity
    group by activity_id
    having count(*) > 1

)

select
    coalesce(activity.type, 'all types') as activity_type,
    count(*) as activities,
    round(100.0 * count(*) filter (where activity.done) / count(*), 1) as pct_done,
    min(activity.due_to) as min_due_at,
    max(activity.due_to) as max_due_at,
    count(distinct activity.deal_id) as distinct_deal_ids,
    count(distinct deal_ids.deal_id) as deal_ids_in_deal_changes,
    count(distinct duplicated_ids.activity_id) as duplicated_activity_ids
from activity
left join deal_ids
    on activity.deal_id = deal_ids.deal_id
left join duplicated_ids
    on activity.activity_id = duplicated_ids.activity_id
group by grouping sets ((activity.type), ())
order by activity.type nulls last

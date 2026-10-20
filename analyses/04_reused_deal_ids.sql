-- Question: are there deal_ids with more than one creation (add_time)?
-- Findings:
--   5 deal_ids (e.g. 399956, 554294) have two add_time events. Their histories interleave:
--   events of each deal share the time-of-day of its add_time (06:45:44 vs 18:27:27 for 399956),
--   and stage 1 is entered a second time. This suggests reused ids or merged deals.
--   Consequence: treated as one deal (counted once per funnel step and month); 5 of 1,995
--   deals does not justify a split heuristic until stakeholders confirm what happened.

with deal_changes as (

    select * from {{ source('postgres_public', 'deal_changes') }}

),

reused as (

    select deal_id
    from deal_changes
    where changed_field_key = 'add_time'
    group by deal_id
    having count(*) > 1

)

select
    deal_changes.deal_id,
    deal_changes.change_time,
    deal_changes.changed_field_key,
    deal_changes.new_value
from deal_changes
inner join reused
    on deal_changes.deal_id = reused.deal_id
order by deal_changes.deal_id, deal_changes.change_time

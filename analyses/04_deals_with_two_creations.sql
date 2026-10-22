-- Question: are there deal_ids with more than one creation (add_time), and are they reopened deals?
-- Findings:
--   5 deal_ids (e.g. 399956, 554294) have two add_time events, each followed by its own lifecycle:
--   events share the time-of-day of their add_time (06:45:44 vs 18:27:27 for 399956), stage 1 is
--   entered twice and each lifecycle ends with its own lost_reason.
--   In all 5 the second creation happens before the first lifecycle is lost, so the two run in
--   parallel; this is not a deal reintroduced after closing. The cause (merge, duplicate, export
--   artefact) is unknown.
--   Consequence: treated as one deal (counted once per funnel step and month); 5 of 1,995
--   deals does not justify a split heuristic until stakeholders confirm what they represent.
with deal_changes as (

    select * from {{ source('postgres_public', 'deal_changes') }}

),

two_creations as (

    select deal_id
    from deal_changes
    where changed_field_key = 'add_time'
    group by deal_id
    having count(*) > 1

)

select
    deal_changes.deal_id,
    min(deal_changes.change_time) filter (where deal_changes.changed_field_key = 'add_time') as first_created_at,
    max(deal_changes.change_time) filter (where deal_changes.changed_field_key = 'add_time') as second_created_at,
    min(deal_changes.change_time) filter (where deal_changes.changed_field_key = 'lost_reason') as first_lost_at,
    max(deal_changes.change_time) filter (where deal_changes.changed_field_key = 'lost_reason') as second_lost_at,
    count(*) filter (
        where deal_changes.changed_field_key = 'stage_id' and deal_changes.new_value = '1'
    ) as stage_1_entries
from deal_changes
inner join two_creations
    on deal_changes.deal_id = two_creations.deal_id
group by deal_changes.deal_id
order by deal_changes.deal_id

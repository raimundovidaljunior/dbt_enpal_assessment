-- Question: are the lookup tables clean and consistent with the funnel definition?
-- Findings:
--   4 duplicate user emails (different user ids); every user_id in deal_changes exists in users.
--   Stage 2 is named 'Qualified lead' in stages but 'Qualified Lead' in the README and fields;
--   the funnel_steps seed carries the README naming.
--   follow_up is inactive and after_close_call is not a funnel step; only meeting (Sales Call 1)
--   and sc_2 (Sales Call 2) are used.

select 'duplicate user email' as check_name, email as value, count(*)::text as detail
from {{ source('postgres_public', 'users') }}
group by email
having count(*) > 1

union all

select 'stage name', stage_id::text, stage_name
from {{ source('postgres_public', 'stages') }}

union all

select 'activity type', type, name || ' (active: ' || active || ')'
from {{ source('postgres_public', 'activity_types') }}

union all

select 'deal_changes users missing from users', count(*)::text, null
from {{ source('postgres_public', 'deal_changes') }} as deal_changes
left join {{ source('postgres_public', 'users') }} as users
    on deal_changes.new_value::int = users.id
where deal_changes.changed_field_key = 'user_id'
    and users.id is null

-- Question: how big is each source table, are its keys unique, and what period does it cover?
-- Findings:
--   deal_changes: 15,406 rows for 1,995 deals, 2024-01-01 to 2025-03-11.
--   activity: 4,579 rows but only 4,568 distinct activity_id (not a unique key), 2024-01-01 to 2024-09-13.
--   users: 1,787 unique ids. stages: 9. activity_types: 4. fields: 4.
--   Activity data stops in 2024-09, while deal stage changes run to 2025-02.

select 'deal_changes' as table_name, count(*) as row_count, count(distinct deal_id) as distinct_keys,
       min(change_time) as min_at, max(change_time) as max_at
from {{ source('postgres_public', 'deal_changes') }}
union all
select 'activity', count(*), count(distinct activity_id), min(due_to), max(due_to)
from {{ source('postgres_public', 'activity') }}
union all
select 'activity_types', count(*), count(distinct type), null, null
from {{ source('postgres_public', 'activity_types') }}
union all
select 'stages', count(*), count(distinct stage_id), null, null
from {{ source('postgres_public', 'stages') }}
union all
select 'users', count(*), count(distinct id), min(modified), max(modified)
from {{ source('postgres_public', 'users') }}
union all
select 'fields', count(*), count(distinct field_key), null, null
from {{ source('postgres_public', 'fields') }}

-- durations must never be negative
select deal_id, 'deal_duration_days' as check_name
from {{ ref('fct_deals') }}
where deal_duration_days < 0

union all

select deal_id, 'days_in_stage' as check_name
from {{ ref('fct_deal_stage_history') }}
where days_in_stage < 0

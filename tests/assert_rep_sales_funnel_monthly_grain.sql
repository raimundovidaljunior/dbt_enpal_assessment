-- one row per month and funnel step, every seed step in every month, no negative counts
select month, funnel_step, 'duplicate month/step' as issue
from {{ ref('rep_sales_funnel_monthly') }}
group by month, funnel_step
having count(*) > 1

union all

select month, null as funnel_step, 'month without every funnel step' as issue
from {{ ref('rep_sales_funnel_monthly') }}
group by month
having count(*) != (select count(*) from {{ ref('funnel_steps') }})

union all

select month, funnel_step, 'negative deals_count' as issue
from {{ ref('rep_sales_funnel_monthly') }}
where deals_count < 0

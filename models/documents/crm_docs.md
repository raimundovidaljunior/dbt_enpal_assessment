{% docs __overview__ %}
# Pipedrive sales funnel

dbt project on the Pipedrive CRM export that builds `rep_sales_funnel_monthly`: distinct deals per
month and funnel step (1–9, plus 2.1 and 3.1 for the sales calls).

Layers: preparation (`prep_pipedrive__`, 1:1 with the source) → intermediate (`int_crm__`,
business logic) → marts (`dim_`, `fct_`) → reporting (`rep_`). The `funnel_steps` seed defines the
funnel steps.

Design, decisions and how to read the report are in `docs/solution.md`; the data profiling
behind them is in `docs/exploratory_analysis.md`, with the queries in `analyses/`.
{% enddocs %}

{% docs deal_id %}
Pipedrive deal id (from `deal_changes`).
{% enddocs %}

{% docs stage_id %}
Pipedrive pipeline stage id. Stage ids 1–9 map to funnel steps 1–9 through the `funnel_steps` seed.
{% enddocs %}

{% docs funnel_step %}
Funnel step number as text (e.g. '2.1'), as defined in the `funnel_steps` seed.
{% enddocs %}

{% docs kpi_name %}
Funnel step name used in reporting (README naming), from the `funnel_steps` seed.
{% enddocs %}

{% docs sort_order %}
Position of the funnel step in the funnel, from the `funnel_steps` seed.
{% enddocs %}

{% docs activity_deal_id %}
Deal id on the activity. It does not link to the deals in `deal_changes`: only 8 of 4,572 match,
about what chance gives (see `analyses/08_activity_deal_overlap.sql`).
{% enddocs %}

{% docs activity_id %}
Pipedrive activity id. Not unique in the source: 11 ids appear twice with different attributes.
{% enddocs %}

{% docs assigned_user_id %}
Pipedrive user the activity is assigned to.
{% enddocs %}

{% docs stage_name %}
Stage name as stored in Pipedrive (stage 2 is 'Qualified lead'); reporting uses the README naming
from the `funnel_steps` seed.
{% enddocs %}

{% docs entered_at %}
Timestamp the deal entered the stage (the `stage_id` change in `deal_changes`).
{% enddocs %}

{% docs previous_stage_id %}
Stage the deal was in before this entry, in time order (null for the first entry).
{% enddocs %}

{% docs sales_call_id %}
Surrogate key over all activity columns (`activity_id` is not unique in the source).
{% enddocs %}

{% docs created_at %}
First `add_time` of the deal.
{% enddocs %}

{% docs owner_user_id %}
Latest owner (`user_id`) of the deal.
{% enddocs %}

{% docs owner_changes_count %}
Number of owner (`user_id`) changes.
{% enddocs %}

{% docs current_stage_id %}
Stage of the deal's latest stage change.
{% enddocs %}

{% docs lost_at %}
Timestamp of the latest `lost_reason` change. Every deal has one, so it marks the end of the deal.
{% enddocs %}

{% docs lost_reason_id %}
Latest lost reason id; labels are in `prep_pipedrive__lost_reasons`.
{% enddocs %}

{% docs lost_reason_name %}
Lost reason label.
{% enddocs %}

{% docs user_id %}
Pipedrive user id.
{% enddocs %}

{% docs user_name %}
User full name.
{% enddocs %}

{% docs email %}
User email. Not unique: 4 emails belong to two user ids each.
{% enddocs %}

{% docs modified_at %}
Last modification timestamp of the user record.
{% enddocs %}

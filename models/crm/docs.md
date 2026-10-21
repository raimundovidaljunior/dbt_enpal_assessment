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

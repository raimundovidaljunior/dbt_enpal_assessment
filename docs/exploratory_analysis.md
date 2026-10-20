# Exploratory analysis

I profiled the raw Pipedrive export before modeling. Every finding below is reproducible: the query is in [`analyses/`](../analyses). Each file starts with the question it answers and what it found. To run them:

```bash
.venv/bin/dbt compile --select "analyses/*" --profiles-dir .
psql -h localhost -U admin -d postgres -f target/compiled/enpal_assessment_project/analyses/<file>.sql
```

## Summary

| # | Finding | Evidence | Consequence for the model |
|---|---|---|---|
| 1 | `deal_changes` is an **event log** (one row per field change), not a deals table. It tracks only 4 fields: `stage_id` 8,906, `user_id` 2,500, `add_time` 2,000, `lost_reason` 2,000. | [01](../analyses/01_source_profile.sql), [02](../analyses/02_deal_changes_fields.sql) | The funnel is built from `stage_id` events (`int_crm__deal_stage_entries`). Any deal attribute (owner, lost reason) would have to be rebuilt from the latest event per field. |
| 2 | **Every deal starts at stage 1**, and **84.4% (1,684 of 1,995) skip at least one stage** (e.g. `1>2>4`). There are only 8 backward moves and 2 same-stage repeats. | [03](../analyses/03_stage_paths.sql) | Counting only recorded entries would under-count the middle of the funnel. Skipped stages are **backfilled** (Pipedrive Insights convention) in a separate model and flagged `is_inferred`. |
| 3 | **Every deal has a `lost_reason`**, including the 324 deals that reached stage 9, and it is always set after the last stage change. | [05](../analyses/05_lost_reasons.sql) | `lost_reason` marks the end of a deal, not a won/lost outcome. It does not remove deals from the funnel. |
| 4 | **5 deal_ids have two creation events** with parallel histories: stage 1 is entered twice, and each lifecycle ends with its own lost reason. The second creation always happens **before the first lifecycle is lost**, so these aren't deals reopened after closing. The cause (merge, duplicate, export artefact) is unknown. | [04](../analyses/04_deals_with_two_creations.sql) | Treated as one deal (counted once per step and month). A split heuristic wasn't worth it for 5 of 1,995 deals until stakeholders confirm what they represent. |
| 5 | **Activity `deal_id`s are unrelated to the deals.** Only 8 of 4,572 exist in `deal_changes`, and random overlap alone would give about 10, because both tables draw from the same 6-digit id range. The 8 matches don't fit together either: 4 calls are due before the deal was created, and 1 after it was lost. Almost every activity `deal_id` has exactly one activity, and no deal shows Sales Call 1 followed by Sales Call 2. | [06](../analyses/06_activity_profile.sql), [08](../analyses/08_activity_deal_overlap.sql) | Steps 2.1 / 3.1 count **sales calls by `due_to` month** (each call has its own `deal_id`), not deals of the stage funnel. Joining them to deals would keep only coincidental matches. The id mapping is an open question. |
| 6 | **`activity_id` is not unique**: 11 ids appear twice with different attributes. About 50% of activities are done. Activity data ends 2024-09-13. | [01](../analyses/01_source_profile.sql), [06](../analyses/06_activity_profile.sql) | Sales calls get a surrogate key (`sales_call_id`). The source uniqueness test is set to `warn`. Steps 2.1 / 3.1 are 0 from 2024-10. |
| 7 | **The activity type key is `type`** (a code), not `id`. `active` is text `'Yes'/'No'`. `follow_up` is inactive. `after_close_call` exists but isn't a funnel step. | [07](../analyses/07_lookups_quality.sql) | Activity types are matched on the `activity_type` code. Sales calls are the types mapped in the `funnel_steps` seed: `meeting` (Sales Call 1) and `sc_2` (Sales Call 2). |
| 8 | Stage 2 is named `Qualified lead` in `stages`, but `Qualified Lead` in the README and `fields`. | [07](../analyses/07_lookups_quality.sql) | The `funnel_steps` seed holds the README naming and numbering. |
| 9 | `users`: 4 duplicate emails (different ids). Every `user_id` referenced by `deal_changes` exists. | [07](../analyses/07_lookups_quality.sql) | Users are keyed on `user_id`, not email. A source relationship test guards activity assignees. |
| 10 | Lost reason labels exist only inside `fields.field_value_options` (JSONB). | `prep_pipedrive__lost_reasons` | They are exploded into a lookup in the preparation layer (the one exception to 1:1 preparation models). |

## Date coverage

| Source | From | To |
|---|---|---|
| `deal_changes` (all events) | 2024-01-01 | 2025-03-11 |
| `deal_changes` stage events | 2024-01-08 | 2025-02-24 |
| `activity` (`due_to`) | 2024-01-01 | 2024-09-13 |

The report covers 2024-01 to 2025-02, the months that have funnel events.

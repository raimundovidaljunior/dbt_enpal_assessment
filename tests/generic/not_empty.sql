-- fails when the relation has no rows: unique, not_null and relationships tests all pass on an
-- empty table, so an empty load would otherwise go unnoticed
{% test not_empty(model) %}

select 1 as failure
where not exists (select 1 from {{ model }})

{% endtest %}

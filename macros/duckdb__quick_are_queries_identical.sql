{#
    DuckDB implementation of dbt-compare's quick_are_queries_identical.

    The VS Code extension's Compare feature calls this macro first to check
    whether two relations hold the same rows. dbt-compare ships versions for
    Snowflake, BigQuery and Databricks only, so without this file Compare fails
    on DuckDB with "quick_are_queries_identical() is not implemented".

    Each side reduces to (row count, sum of row hashes). Summing is
    order-independent and, unlike XOR, does not cancel out duplicate rows.
#}
{% macro duckdb__quick_are_queries_identical(query_a, query_b, columns, event_time) %}
    {% set quoted_cols = [] %}
    {% for col in columns %}
        {% do quoted_cols.append(adapter.quote(col)) %}
    {% endfor %}
    {% set joined_cols = quoted_cols | join(", ") %}

    {% set filter = "" %}
    {% if event_time %}
        {% set bounds = dbt_compare_macros._get_comparison_bounds(query_a, query_b, event_time) %}
        {% if bounds %}
            {% set filter = "where " ~ bounds["event_time"] ~ " >= '" ~ bounds["min_event_time"] ~ "' and "
                ~ bounds["event_time"] ~ " <= '" ~ bounds["max_event_time"] ~ "'" %}
        {% endif %}
    {% endif %}

    select count(distinct hash_result) = 1 as are_tables_identical
    from (
        select count(*)::varchar || ':' || coalesce(sum(hash({{ joined_cols }})::hugeint), 0)::varchar as hash_result
        from ({{ query_a }}) query_a_subq
        {{ filter }}

        union all

        select count(*)::varchar || ':' || coalesce(sum(hash({{ joined_cols }})::hugeint), 0)::varchar as hash_result
        from ({{ query_b }}) query_b_subq
        {{ filter }}
    ) as hashes
{% endmacro %}

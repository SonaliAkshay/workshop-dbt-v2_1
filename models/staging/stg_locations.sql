with

source as (

    -- {# Reads the seeded table as a source (run dbt seed first) so the dbt VS Code extension can show column-level lineage. #}
    select * from {{ source('ecom', 'raw_stores') }}

),

renamed as (

    select

        ----------  ids
        id as location_id,

        ---------- text
        name as location_name,

        ---------- numerics
        tax_rate,

        ---------- timestamps
        cast(opened_at as date) as opened_date

    from source

)

select * from renamed

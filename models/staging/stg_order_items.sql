with

source as (

    -- {# Reads the seeded table as a source (run dbt seed first) so the dbt VS Code extension can show column-level lineage. #}
    select * from {{ source('ecom', 'raw_items') }}

),

renamed as (

    select

        ----------  ids
        id as order_item_id,
        order_id,
        sku as product_id

    from source

)

select * from renamed

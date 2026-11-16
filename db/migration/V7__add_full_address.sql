ALTER TABLE gnaf.gnaf_core
ADD COLUMN IF NOT EXISTS full_address text GENERATED ALWAYS AS (
    NULLIF(RTRIM(
        COALESCE(NULLIF(BTRIM(building_name), '') || ', ', '') ||
        CASE
            WHEN NULLIF(BTRIM(address_site_name), '') IS NOT NULL
             AND UPPER(BTRIM(address_site_name)) IS DISTINCT FROM UPPER(BTRIM(building_name))
            THEN BTRIM(address_site_name) || ', '
            ELSE ''
        END ||
        COALESCE(NULLIF(BTRIM(
            COALESCE(flat_type_code, '') || ' ' ||
            COALESCE(flat_number_prefix, '') || COALESCE(flat_number, '') ||
            COALESCE(flat_number_suffix, '')
        ), '') || ', ', '') ||
        COALESCE('LEVEL ' || NULLIF(BTRIM(
            COALESCE(level_number_prefix, '') || COALESCE(level_number::text, '') ||
            COALESCE(level_number_suffix, '')
        ), '') || ', ', '') ||
        COALESCE('LOT ' || NULLIF(BTRIM(
            COALESCE(lot_number_prefix, '') || COALESCE(lot_number, '') ||
            COALESCE(lot_number_suffix, '')
        ), '') || ', ', '') ||
        COALESCE(NULLIF(BTRIM(
            COALESCE(number_first_prefix, '') || COALESCE(number_first::text, '') ||
            COALESCE(number_first_suffix, '') ||
            CASE
                WHEN NULLIF(BTRIM(
                    COALESCE(number_last_prefix, '') || COALESCE(number_last::text, '') ||
                    COALESCE(number_last_suffix, '')
                ), '') IS NOT NULL
                THEN CASE
                    WHEN NULLIF(BTRIM(
                        COALESCE(number_first_prefix, '') || COALESCE(number_first::text, '') ||
                        COALESCE(number_first_suffix, '')
                    ), '') IS NOT NULL THEN '-'
                    ELSE ''
                END || COALESCE(number_last_prefix, '') || COALESCE(number_last::text, '') ||
                    COALESCE(number_last_suffix, '')
                ELSE ''
            END || ' ' ||
            COALESCE(NULLIF(BTRIM(street_name), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(street_type_code), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(street_suffix_code), ''), '')
        ), '') || ', ', '') ||
        BTRIM(
            COALESCE(NULLIF(BTRIM(locality_name), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(state_abbreviation), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(postcode), ''), '')
        ),
        ', '
    ), '')
) VIRTUAL;
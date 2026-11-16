-- Build a full address from the available parts and skip any blank parts.
ALTER TABLE gnaf.gnaf_core
ADD COLUMN IF NOT EXISTS full_address text GENERATED ALWAYS AS (

    /* Converts an empty final address into null and removes any trailing commas or spaces on the right side of the address. */
    NULLIF(RTRIM(

        /* BTRIM removes leading and trailing spaces from building_name. */
        /* NULLIF converts a blank building name ('') into NULL. */
        /* ', ' is appended after the building name when a value exists. */
        /* COALESCE returns an empty string when building_name is NULL. */
        COALESCE(NULLIF(BTRIM(building_name), '') || ', ', '') ||
    

        /*Only includes address_site_name when it contains a value, is different from building_name and makes it case insensitive*/
        CASEd
            WHEN NULLIF(BTRIM(address_site_name), '') IS NOT NULL
             AND UPPER(BTRIM(address_site_name)) IS DISTINCT FROM UPPER(BTRIM(building_name))
            THEN BTRIM(address_site_name) || ', '
            ELSE ''
        END ||
       
       
       
       
        /* Builds the string for the flat/unit details. Combines the type, number, and suffix components. Trims any leading and trailing spaces. Appends a comma when a value exists. */
        COALESCE(NULLIF(BTRIM(
            COALESCE(flat_type_code, '') || ' ' ||
            COALESCE(flat_number_prefix, '') || COALESCE(flat_number, '') ||
            COALESCE(flat_number_suffix, '')
        ), '') || ', ', '') ||
        
        
        /* Builds the string for the level details. Starting the string with 'LEVEL ' when a value exists. Combing the prefix, number, 
        and suffix components. Trimming any leading and trailing spaces on both sides. */
        COALESCE('LEVEL ' || NULLIF(BTRIM(
            COALESCE(level_number_prefix, '') || COALESCE(level_number::text, '') ||
            COALESCE(level_number_suffix, '')
        ), '') || ', ', '') ||

        /* Builds the string for the lot details. Starting the string with 'LOT ' when a value exists. Combines the prefix, number, and suffix components. 
        Trims any leading and trailing spaces. Appends a comma when a value exists. */
        COALESCE('LOT ' || NULLIF(BTRIM(
            COALESCE(lot_number_prefix, '') || COALESCE(lot_number, '') ||
            COALESCE(lot_number_suffix, '')
        ), '') || ', ', '') ||

        /* Add the street number or number range, followed by street details. */
        COALESCE(NULLIF(BTRIM(
            COALESCE(number_first_prefix, '') || COALESCE(number_first::text, '') ||
            COALESCE(number_first_suffix, '') ||
            CASE
                /* Include the end number only when it is provided. */
                WHEN NULLIF(BTRIM(
                    COALESCE(number_last_prefix, '') || COALESCE(number_last::text, '') ||
                    COALESCE(number_last_suffix, '')
                ), '') IS NOT NULL
                /* Separate the start and end numbers with a hyphen. */
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
            /* Add the street name, type, and suffix after the street number. */
            COALESCE(NULLIF(BTRIM(street_name), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(street_type_code), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(street_suffix_code), ''), '')
        ), '') || ', ', '') ||
        /* Add locality, state, and postcode, leaving out any blank values. */
        BTRIM(
            COALESCE(NULLIF(BTRIM(locality_name), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(state_abbreviation), '') || ' ', '') ||
            COALESCE(NULLIF(BTRIM(postcode), ''), '')
        ),
        ', '
    ), '')
) VIRTUAL; -- Build this value when the row is queried; do not store it in the table.
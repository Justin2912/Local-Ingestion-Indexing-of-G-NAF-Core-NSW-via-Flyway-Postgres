-- Populate address number, flat, level, and lot prefixes and suffixes.
UPDATE gnaf.gnaf_core gc
SET
    lot_number_prefix = ad.lot_number_prefix,
    lot_number_suffix = ad.lot_number_suffix,
    flat_number_prefix = ad.flat_number_prefix,
    flat_number_suffix = ad.flat_number_suffix,
    level_number_prefix = ad.level_number_prefix,
    level_number_suffix = ad.level_number_suffix,
    number_first_prefix = ad.number_first_prefix,
    number_first_suffix = ad.number_first_suffix,
    number_last_prefix = ad.number_last_prefix,
    number_last_suffix = ad.number_last_suffix
FROM public.address_detail ad
WHERE gc.address_detail_pid = ad.address_detail_pid;

-- Add address aliases and get their postcode and state from the linked address.
INSERT INTO gnaf.gnaf_core_alias (
    address_alias_pid,
    alias_pid,
    principal_pid,
    locality_primary_postcode,
    state_abbreviation,
    date_created,
    date_retired
)
-- If identical data appears more than once, return it only once.
SELECT DISTINCT
    address_alias.address_alias_pid,
    address_alias.alias_pid,
    address_alias.principal_pid,
    address_locality.primary_postcode,
    address_state.state_abbreviation,
    address_alias.date_created,
    address_alias.date_retired
FROM public.address_alias address_alias
-- Find the locality for the alias address.
LEFT JOIN public.address_detail alias_address
    ON alias_address.address_detail_pid = address_alias.alias_pid
-- Get the primary postcode and state for that locality.
LEFT JOIN public.locality address_locality
    ON address_locality.locality_pid = alias_address.locality_pid
LEFT JOIN public.state address_state
    ON address_state.state_pid = address_locality.state_pid
-- Skip this insert if the alias ID is already in the target table.

--Prevents duplicaye address alias fromm being inserted
WHERE NOT EXISTS (
    -- EXISTS only checks whether a matching row exists and the selected value itself is ignored.
    SELECT 1
    FROM gnaf.gnaf_core_alias core_alias
    WHERE core_alias.address_alias_pid = address_alias.address_alias_pid
);

-- Add locality aliases and link each alias name to its correct locality ID.
INSERT INTO gnaf.gnaf_core_alias (
    locality_alias_pid,
    locality_alias_name,
    locality_pid,
    locality_primary_postcode,
    state_abbreviation,
    date_created,
    date_retired
)
-- If identical data appears more than once, return it only once.
SELECT DISTINCT
    locality_alias.locality_alias_pid,
    locality_alias.name,
    locality_alias.locality_pid,
    locality.primary_postcode,
    state.state_abbreviation,
    locality_alias.date_created,
    locality_alias.date_retired
FROM public.locality_alias locality_alias
-- Find the locality record linked to this locality alias.
LEFT JOIN public.locality locality
    ON locality.locality_pid = locality_alias.locality_pid
-- Retrieves the states using the alias's state ID.
LEFT JOIN public.state state
    ON state.state_pid = locality_alias.state_pid
-- Skip this insert if the alias ID is already in the target table.
WHERE NOT EXISTS (
    -- The value 1 is a placeholder; this check only looks for a matching row.
    SELECT 1
    FROM gnaf.gnaf_core_alias core_alias
    WHERE core_alias.locality_alias_pid = locality_alias.locality_alias_pid
);

-- Add street aliases and link each alias street to its correct street/locality ID.
INSERT INTO gnaf.gnaf_core_alias (
    street_locality_alias_pid,
    street_locality_alias_street_name,
    street_locality_alias_street_type_code,
    street_locality_alias_street_suffix_code,
    street_locality_pid,
    locality_primary_postcode,
    state_abbreviation,
    date_created,
    date_retired
)
-- If identical data appears more than once, return it only once.
SELECT DISTINCT
    street_alias.street_locality_alias_pid,
    street_alias.street_name,
    street_alias.street_type_code,
    street_alias.street_suffix_code,
    street_alias.street_locality_pid,
    locality.primary_postcode,
    state.state_abbreviation,
    street_alias.date_created,
    street_alias.date_retired
    
FROM public.street_locality_alias street_alias
-- Find the street/locality record linked to this street alias.
LEFT JOIN public.street_locality street_locality
    ON street_locality.street_locality_pid = street_alias.street_locality_pid
-- Find the locality that contains the linked street record.
LEFT JOIN public.locality locality
    ON locality.locality_pid = street_locality.locality_pid
-- Get the state abbreviation for that locality.
LEFT JOIN public.state state
    ON state.state_pid = locality.state_pid
-- Skip this insert if the alias ID is already in the target table.
WHERE NOT EXISTS (
    -- The value 1 is a placeholder; this check only looks for a matching row.
    SELECT 1
    FROM gnaf.gnaf_core_alias core_alias
    WHERE core_alias.street_locality_alias_pid = street_alias.street_locality_alias_pid
);

-- Update postcode and state for address aliases already in the table.
UPDATE gnaf.gnaf_core_alias AS core_alias
SET locality_primary_postcode = address_locality.primary_postcode,
    state_abbreviation = address_state.state_abbreviation
FROM public.address_alias address_alias
-- Find the alias address and its locality.
JOIN public.address_detail alias_address
    ON alias_address.address_detail_pid = address_alias.alias_pid
-- Get the locality's primary postcode.
JOIN public.locality address_locality
    ON address_locality.locality_pid = alias_address.locality_pid
-- Get the locality's state abbreviation when available.
LEFT JOIN public.state address_state
    ON address_state.state_pid = address_locality.state_pid
-- Match this alias row and update it only when its postcode or state differs.
WHERE core_alias.address_alias_pid = address_alias.address_alias_pid
  AND (
    core_alias.locality_primary_postcode IS DISTINCT FROM address_locality.primary_postcode
        OR core_alias.state_abbreviation IS DISTINCT FROM address_state.state_abbreviation
  );

-- Update postcode and state for locality aliases already in the table.
UPDATE gnaf.gnaf_core_alias AS core_alias
SET locality_primary_postcode = locality.primary_postcode,
    state_abbreviation = state.state_abbreviation
FROM public.locality_alias locality_alias
-- Find the locality record linked to this alias.
LEFT JOIN public.locality locality
    ON locality.locality_pid = locality_alias.locality_pid
-- Get the state abbreviation using the alias's state ID.
LEFT JOIN public.state state
    ON state.state_pid = locality_alias.state_pid
-- Match this alias row and update it only when its postcode or state differs.
WHERE core_alias.locality_alias_pid = locality_alias.locality_alias_pid
  AND (
    core_alias.locality_primary_postcode IS DISTINCT FROM locality.primary_postcode
        OR core_alias.state_abbreviation IS DISTINCT FROM state.state_abbreviation
  );

-- Update postcode and state for street aliases already in the table.
UPDATE gnaf.gnaf_core_alias AS core_alias
SET locality_primary_postcode = locality.primary_postcode,
    state_abbreviation = state.state_abbreviation
FROM public.street_locality_alias street_alias
-- Find the street/locality record linked to this street alias.
JOIN public.street_locality street_locality
    ON street_locality.street_locality_pid = street_alias.street_locality_pid
-- Find the locality that contains the linked street record.
JOIN public.locality locality
    ON locality.locality_pid = street_locality.locality_pid
-- Get the locality's state abbreviation when available.
LEFT JOIN public.state state
    ON state.state_pid = locality.state_pid
-- Match the alias row and update it only when its postcode or state differs.
WHERE core_alias.street_locality_alias_pid = street_alias.street_locality_alias_pid
  AND (
    core_alias.locality_primary_postcode IS DISTINCT FROM locality.primary_postcode
        OR core_alias.state_abbreviation IS DISTINCT FROM state.state_abbreviation
  );

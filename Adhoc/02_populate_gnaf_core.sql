-- Load the public G-NAF source tables before running this script.
-- Re-running this insert adds the rows again unless the target is cleared.

-- Build core address rows from ADDRESS_DETAIL and its related lookup tables.

INSERT INTO gnaf.gnaf_core (
    address_detail_pid,
    postcode,
    locality_name,
    state_abbreviation,
    alias_principal,
    street_name,
    street_type_code,
    address_site_name,
    flat_type_code,
    flat_number,
    number_first,
    number_last,
    building_name,
    latitude,
    longitude,
    level_number,
    level_type_aut_name,
    lot_number,
    street_suffix_code,
    date_created,
    date_retired,
    date_modified,
    lot_number_prefix,
    lot_number_suffix,
    flat_number_prefix,
    flat_number_suffix,
    level_number_prefix,
    level_number_suffix,
    number_first_prefix,
    number_first_suffix,
    number_last_prefix,
    number_last_suffix
)
SELECT
    ad.address_detail_pid,
    ad.postcode,
    locality.locality_name,
    state.state_abbreviation,
    ad.alias_principal,
    street_locality.street_name,
    street_locality.street_type_code,
    address_site.address_site_name,
    ad.flat_type_code,
    ad.flat_number,
    ad.number_first,
    ad.number_last,
    ad.building_name,
    geocode.latitude,
    geocode.longitude,
    ad.level_number,
    level_type.name,
    ad.lot_number,
    street_locality.street_suffix_code,
    ad.date_created,
    ad.date_retired,
    CURRENT_TIMESTAMP, -- Record when this row was loaded.
    ad.lot_number_prefix,
    ad.lot_number_suffix,
    ad.flat_number_prefix,
    ad.flat_number_suffix,
    ad.level_number_prefix,
    ad.level_number_suffix,
    ad.number_first_prefix,
    ad.number_first_suffix,
    ad.number_last_prefix,
    ad.number_last_suffix
-- Keep each address-detail row and add matching locality and state values.
FROM public.address_detail ad
-- Match ADDRESS_DETAIL.LOCALITY_PID to get the locality name.
LEFT JOIN public.locality locality
    ON locality.locality_pid = ad.locality_pid
-- Match LOCALITY.STATE_PID to get the state abbreviation.
LEFT JOIN public.state state
    ON state.state_pid = locality.state_pid
-- Match ADDRESS_DETAIL.STREET_LOCALITY_PID to get street details.
LEFT JOIN public.street_locality street_locality
    ON street_locality.street_locality_pid = ad.street_locality_pid
-- Match ADDRESS_DETAIL.ADDRESS_SITE_PID to get the site name.
LEFT JOIN public.address_site address_site
    ON address_site.address_site_pid = ad.address_site_pid
-- Translate the level type code into its descriptive address label.
LEFT JOIN public.level_type_aut level_type
    ON level_type.code = ad.level_type_code
-- Match ADDRESS_DETAIL_PID to get the default geocode coordinates.
LEFT JOIN public.address_default_geocode geocode
    ON geocode.address_detail_pid = ad.address_detail_pid;

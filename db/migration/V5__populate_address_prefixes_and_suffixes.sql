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
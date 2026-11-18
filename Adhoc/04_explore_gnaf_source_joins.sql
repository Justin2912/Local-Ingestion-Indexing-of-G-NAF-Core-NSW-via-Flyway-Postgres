-- ADDRESS_DETAIL joins to LOCALITY on LOCALITY_PID
SELECT
    ad.address_detail_pid,
    ad.locality_pid,
    l.locality_pid,
    l.locality_name
FROM public.address_detail ad
LEFT JOIN public.locality l
    ON ad.locality_pid = l.locality_pid;


--Locality joins to State on state_pid
SELECT
    l.locality_name,
    l.state_pid,
    s.state_pid,
    s.state_name,
    s.state_abbreviation
FROM public.locality l
LEFT JOIN public.state s
    ON l.state_pid = s.state_pid;

-- Address_Detail joins to Street Locality on street_locality_pid
select
    ad.street_locality_pid,
    sl.street_locality_pid,
    sl.street_name,
    sl.street_type_code,
    sl.street_suffix_code
FROM public.address_detail ad
LEFT JOIN public.street_locality sl
    ON ad.street_locality_pid = sl.street_locality_pid;

--Address_Detail joins to Address_Site on address_site_pid
SELECT
    ad.address_site_pid,
    ads.address_site_pid,
    ads.address_site_name,
    ads.address_type
FROM public.address_detail ad
LEFT JOIN public.address_site ads
    ON ad.address_site_pid = ads.address_site_pid;


-- ADDRESS_DETAIL joins to ADDRESS_DEFAULT_GEOCODE on ADDRESS_DETAIL_PID
SELECT
    ad.address_detail_pid,
    dg.address_detail_pid,
    dg.latitude,
    dg.longitude
FROM public.address_detail ad
LEFT JOIN public.address_default_geocode dg
    ON ad.address_detail_pid = dg.address_detail_pid;

-- LOCALITY joins to LOCALITY_ALIAS on LOCALITY_PID
SELECT
    l.locality_pid,
    la.locality_pid,
    l.locality_name,
    la.name AS locality_alias
FROM public.locality l
LEFT JOIN public.locality_alias la
    ON l.locality_pid = la.locality_pid;

--Street_locality joins to locality on locality_pid
SELECT
    sl.street_name,
    sl.street_locality_pid,
    sl.locality_pid,
    l.locality_pid,
    l.locality_name
FROM public.street_locality sl
LEFT JOIN public.locality l
    ON sl.locality_pid = l.locality_pid;

-- STREET_LOCALITY joins to STREET_LOCALITY_ALIAS on STREET_LOCALITY_PID
SELECT
    sl.street_locality_pid,
    sla.street_locality_pid,
    sl.street_name,
    sla.street_name AS street_alias,
    sl.street_type_code,
    sla.street_type_code
FROM public.street_locality sl
LEFT JOIN public.street_locality_alias sla
    ON sl.street_locality_pid = sla.street_locality_pid;

-- ADDRESS_DETAIL joins to ADDRESS_ALIAS on PRINCIPAL_PID
SELECT
    ad.address_detail_pid,
    aa.principal_pid,
    aa.alias_pid,
    aa.alias_type_code
FROM public.address_detail ad
LEFT JOIN public.address_alias aa
    ON ad.address_detail_pid = aa.principal_pid;

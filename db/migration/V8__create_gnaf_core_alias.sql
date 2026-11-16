CREATE TABLE IF NOT EXISTS gnaf.gnaf_core_alias (
    alias_kind varchar(20) NOT NULL,
    alias_record_pid varchar(15) NOT NULL,
    alias_type_code varchar(10) NOT NULL,
    date_created date NOT NULL,
    date_retired date,
    alias_pid varchar(15),
    principal_pid varchar(15),
    locality_pid varchar(15),
    street_locality_pid varchar(15),
    alias_name varchar(100),
    street_type_code varchar(15),
    street_suffix_code varchar(15),
    state_pid varchar(15),
    postcode varchar(4),
    alias_comment varchar(200),
    PRIMARY KEY (alias_kind, alias_record_pid),
    CHECK (
        (alias_kind = 'address' AND alias_pid IS NOT NULL AND principal_pid IS NOT NULL
            AND locality_pid IS NULL AND street_locality_pid IS NULL AND alias_name IS NULL)
        OR (alias_kind = 'locality' AND locality_pid IS NOT NULL AND alias_name IS NOT NULL
            AND state_pid IS NOT NULL AND alias_pid IS NULL AND principal_pid IS NULL
            AND street_locality_pid IS NULL)
        OR (alias_kind = 'street_locality' AND street_locality_pid IS NOT NULL
            AND alias_name IS NOT NULL AND alias_pid IS NULL AND principal_pid IS NULL
            AND locality_pid IS NULL)
    )
);
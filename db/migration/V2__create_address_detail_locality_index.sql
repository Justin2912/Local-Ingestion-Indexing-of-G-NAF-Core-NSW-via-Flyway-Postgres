CREATE INDEX idx_address_detail_postcode
ON address_detail(postcode);

CREATE INDEX idx_address_detail_locality_pid
ON address_detail(locality_pid);

CREATE INDEX idx_address_detail_street_locality_pid
ON address_detail(street_locality_pid);

CREATE INDEX idx_address_detail_address_site_pid
ON address_detail(address_site_pid);

CREATE INDEX idx_locality_name
ON locality(locality_name);

CREATE INDEX idx_locality_state_pid
ON locality(state_pid);

CREATE INDEX idx_state_name
ON state(state_name);

CREATE INDEX idx_state_abbreviation
ON state(state_abbreviation);

CREATE INDEX idx_locality_postcode
ON locality(primary_postcode);

CREATE INDEX idx_street_locality_name
ON street_locality(street_name);

CREATE INDEX idx_street_locality_locality_pid
ON street_locality(locality_pid);

CREATE INDEX idx_street_locality_type
ON street_locality(street_type_code);

CREATE INDEX idx_address_site_name
ON address_site(address_site_name);

CREATE INDEX idx_flat_number 
ON address_detail(flat_number);


CREATE INDEX idx_address_detail_number_first
ON address_detail(number_first);


CREATE INDEX idx_flat_type
ON address_detail(flat_type_code);
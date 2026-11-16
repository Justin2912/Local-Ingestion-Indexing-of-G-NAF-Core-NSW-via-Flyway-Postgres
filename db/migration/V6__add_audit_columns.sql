ALTER TABLE gnaf.gnaf_core ADD COLUMN IF NOT EXISTS date_created date NULL;

ALTER TABLE gnaf.gnaf_core ADD COLUMN IF NOT EXISTS date_retired date NULL;

ALTER TABLE gnaf.gnaf_core ADD COLUMN IF NOT EXISTS date_modified timestamptz DEFAULT CURRENT_TIMESTAMP NULL;
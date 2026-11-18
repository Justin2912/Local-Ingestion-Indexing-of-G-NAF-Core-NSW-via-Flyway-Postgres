-- Remove extra rows when an address_detail_pid appears more than once.
-- One copy is kept; it does not matter which copy.
DELETE FROM gnaf.gnaf_core g
USING (
    -- Number rows that share the same address_detail_pid.
    SELECT ctid AS row_id
    FROM (
        SELECT ctid,
               ROW_NUMBER() OVER (
                   PARTITION BY address_detail_pid
                   ORDER BY ctid
               ) AS rn
        FROM gnaf.gnaf_core
    ) numbered
    -- Mark all but the first row for deletion.
    WHERE rn > 1
) duplicates
-- Delete the rows marked above.
WHERE g.ctid = duplicates.row_id;
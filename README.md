# Rebuild G-NAF Core (NSW)

This project loads Geoscape G-NAF address data into a local PostgreSQL database
and combines it into `gnaf.gnaf_core` for address queries. Flyway creates the
source tables in `public`, the core table in `gnaf`, and its generated
`full_address` column. The Python loader and SQL population script load the
rows separately.

## Prerequisites

These commands are for Windows PowerShell. Run them from the repository root,
the folder containing `db` and `Adhoc`.

- [PostgreSQL](https://www.postgresql.org/download/windows/) 17.9 or 18, with a
  running server and `psql` and `createdb` on `PATH`. The examples use a local
  server at `localhost:5432` and a `postgres` account that can create databases
  and schemas.
- [Flyway CLI](https://documentation.red-gate.com/flyway/getting-started-with-flyway/quickstart-guides/quickstart-command-line)
  with PostgreSQL support, on `PATH`.
- [Python](https://www.python.org/downloads/) 3.10 or later, on `PATH`. Install
  `psycopg` in a virtual environment:

  ```powershell
  python -m venv .venv
  .\.venv\Scripts\python.exe -m pip install "psycopg[binary]"
  ```

## Rebuild in order

### 1. Extract the G-NAF data

Download a [Geoscape G-NAF release](https://geoscape.com.au/g-naf/). Use a
release whose PSV column layout matches [V1](db/migration/V1__create_geoscape_gnaf_table.sql);
the loader copies by column position, not by header name. Keep the supplied
file names and put the files directly in these directories:

```text
C:\GNAF\
    Authority Code\
        Authority_Code_LEVEL_TYPE_AUT_psv.psv
        ...other authority PSV files...
    Standard\
        NSW_ADDRESS_DETAIL_psv.psv
        ...other NSW standard PSV files...
```

Include all authority files for the release and all NSW standard files. Do not
put other states' standard files in this folder for an NSW-only rebuild. The
loader processes every `.psv` directly inside the two folders; it does not
search subfolders.

Optional: [00_find_street_locality_alias_files.py](Adhoc/00_find_street_locality_alias_files.py)
lists street-locality alias PSV files without loading them. Set `gnaf_folder`
in the script to `Path(r"C:\GNAF\Standard")`, then run:

```powershell
.\.venv\Scripts\python.exe -m pip install pandas
.\.venv\Scripts\python.exe .\Adhoc\00_find_street_locality_alias_files.py
```

### 2. Create a new database and configure the tools

```powershell
createdb -h localhost -p 5432 -U postgres gnaf_rebuild
```

If `gnaf_rebuild` already exists, choose a new name and use it consistently
below. Do not reuse a populated database for these steps. A fresh database
does not need `flyway clean`.

Create a local `flyway.conf` in the repository root (ignored by Git):

```properties
flyway.url=jdbc:postgresql://localhost:5432/gnaf_rebuild
flyway.user=postgres
flyway.locations=filesystem:db/migration
flyway.defaultSchema=public
```

In [01_load_gnaf_source_tables.py](Adhoc/01_load_gnaf_source_tables.py), set `ROOT` to
`Path(r"C:\GNAF")` and set `DB_CONFIG` to the same host, port, database, user,
and database password. If your connection differs from the example, also
update the `psql` commands below. Do not commit passwords or your local loader
settings.

### 3. Apply the Flyway migrations

[V3](db/migration/V3__add_full_address.sql) uses a `STORED` generated column,
supported by PostgreSQL 17.9 and 18. PostgreSQL computes and saves the address
on insert or update. Editing a migration that already ran can cause a Flyway
checksum mismatch and does not update the existing column.

```powershell
$credential = Get-Credential -UserName postgres -Message 'Enter the PostgreSQL password for Flyway'
$env:FLYWAY_PASSWORD = $credential.GetNetworkCredential().Password
flyway "-configFiles=flyway.conf" migrate
```

If `migrate` succeeds, check the migration history in the same PowerShell session:

```powershell
flyway "-configFiles=flyway.conf" info
Remove-Item Env:\FLYWAY_PASSWORD
Remove-Variable credential
```

Stop if a command fails. Check that V1, V2, and V3 succeeded before loading
data. At this point the tables exist but are empty.

### 4. Load the source tables, then populate the core table

Run [01_load_gnaf_source_tables.py](Adhoc/01_load_gnaf_source_tables.py)
first and wait for `Load complete`:

```powershell
.\.venv\Scripts\python.exe .\Adhoc\01_load_gnaf_source_tables.py
```

Only then run [02_populate_gnaf_core.sql](Adhoc/02_populate_gnaf_core.sql):

```powershell
psql -h localhost -p 5432 -U postgres -d gnaf_rebuild -v ON_ERROR_STOP=1 -f .\Adhoc\02_populate_gnaf_core.sql
```

The insert starts from `public.address_detail` and left-joins locality, state,
street, site, default geocode, and level-type data. It loads the level name
from `public.level_type_aut` and does not filter to current or principal
addresses. Do not rerun either load blindly: the Python loader commits each
file separately, so a failed load can leave partial data, and rerunning the
core insert appends duplicate rows. For a clean retry, start with a new empty
database.

### 5. Verify the results

Open a `psql` session against the same database:

```powershell
psql -h localhost -p 5432 -U postgres -d gnaf_rebuild
```

Run:

```sql
SELECT COUNT(*) AS source_rows FROM public.address_detail;

SELECT COUNT(*) AS core_rows,
       COUNT(DISTINCT address_detail_pid) AS distinct_address_ids
FROM gnaf.gnaf_core;

SELECT address_detail_pid, COUNT(*) AS copies
FROM gnaf.gnaf_core
GROUP BY address_detail_pid
HAVING COUNT(*) > 1
ORDER BY copies DESC
LIMIT 20;

SELECT level_type_aut_name, level_number, full_address
FROM gnaf.gnaf_core
WHERE level_type_aut_name IS NOT NULL
LIMIT 20;
```

Expect nonzero row counts. Compare the number of distinct core address IDs
with the source count and inspect any duplicates before deleting anything:
joins can produce multiple rows for one address ID. Use `\q` to exit `psql`.

### 6. Optional Adhoc scripts

- **[03_deduplicate_gnaf_core.sql](Adhoc/03_deduplicate_gnaf_core.sql):** Run only after
  verifying that duplicates exist and that you can discard the extra rows.
  The script keeps one row per address ID based on `ctid`, not data quality
  or recency. Recheck the counts after running it.

  ```powershell
  psql -h localhost -p 5432 -U postgres -d gnaf_rebuild -v ON_ERROR_STOP=1 -f .\Adhoc\03_deduplicate_gnaf_core.sql
  ```

- **[04_explore_gnaf_source_joins.sql](Adhoc/04_explore_gnaf_source_joins.sql):** Optional read-only exploration once the
  Python loader has finished. It queries the source tables, not the core
  table, and can return many rows.

  ```powershell
  psql -h localhost -p 5432 -U postgres -d gnaf_rebuild -v ON_ERROR_STOP=1 -f .\Adhoc\04_explore_gnaf_source_joins.sql
  ```

- **[populate_backup.sql](Adhoc/archive/populate_backup.sql):** Historical reference.
  **Do not run it during a rebuild.** It writes to tables, including
  `gnaf.gnaf_core_alias`, which the current migrations do not create.

## How `full_address` is built

[V3](db/migration/V3__add_full_address.sql) assembles these parts in order:

1. Level, formatted from `level_type_aut_name` before the building name.
   `LEVEL` and `FLOOR` require a `level_number` and display it with any
   prefix or suffix. All other types, such as `PARKING` and `MEZZANINE`,
   display only the name, even if G-NAF supplies a number. The level is
   omitted if the type is blank or if `LEVEL` or `FLOOR` has no number.
2. Building name.
3. Address site name, unless it matches the building name after trimming
   spaces and ignoring case.
4. Flat or unit type code and number, with any prefix or suffix.
5. `LOT` plus the lot number with any prefix or suffix, if present.
6. Street number or hyphenated range, then street name, type code, and suffix.
7. Locality, state abbreviation, and postcode, separated by spaces.

Missing or blank parts are skipped rather than leaving empty comma-separated
segments. If nothing remains, `full_address` is `NULL`. These rules affect
only the displayed address, not the source level or unit numbers.

Examples:

- `LEVEL 1, MELBOURNE CENTRAL, SHOP 150, 300 LONSDALE STREET, MELBOURNE VIC 3000`
- `PARKING, CENTRO BRANDON PARK, 580 SPRINGVALE ROAD, WHEELERS HILL VIC 3150` (`PARKING 1` displays as `PARKING`)
- `PARKING, UNIT 5P3, 628 FLINDERS STREET, DOCKLANDS VIC 3008` (the unit number stays unchanged)

from pathlib import Path
import psycopg

# Connection details for the local PostgreSQL database.
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "gnaf_rebuild",
    "user": "postgres",
    "password": "12345"
}

# Root folder that contains the G-NAF data folders.
ROOT = Path(r"C:\Users\Justin.Lam\Desktop\GNAFAUGUST2026")

# Authority tables and state-specific data are stored separately.
AUTHORITY_DIR = ROOT / "Authority Code"
STANDARD_DIR = ROOT / "Standard"

# Valid state or territory prefixes at the start of standard file names.
STATE_PREFIXES = {
    "ACT",
    "NSW",
    "NT",
    "OT",
    "QLD",
    "SA",
    "TAS",
    "VIC",
    "WA"
}


def authority_table_name(file_name: str) -> str:
    # Remove the standard filename prefix and extension to get the table name.
    return (
        file_name
        .replace("Authority_Code_", "")
        .replace("_psv.psv", "")
    )


def state_table_name(file_name: str) -> str:
    # Remove the extension, then separate the state prefix from the table name.
    parts = file_name.replace("_psv.psv", "").split("_")

    state = parts[0]

    if state not in STATE_PREFIXES:
        raise ValueError(f"Unexpected state prefix: {state}")

    return "_".join(parts[1:])


def copy_file(conn, table_name: str, file_path: Path):
    print(f"Loading {file_path.name} -> {table_name}")

    # COPY imports pipe-separated rows and uses the first row as column headers.
    sql = f"""
    COPY {table_name}
    FROM STDIN
    WITH (
        FORMAT csv,
        DELIMITER '|',
        HEADER true
    )
    """

    # Stream the file in chunks instead of reading the whole file into memory.
    with conn.cursor() as cur:
        with open(file_path, "r", encoding="utf-8") as f:
            with cur.copy(sql) as copy:
                while data := f.read(1024 * 1024):
                    copy.write(data)

    # Save the rows loaded from this file.
    conn.commit()


def main():
    # Open one database connection for all file imports.
    conn = psycopg.connect(**DB_CONFIG)

    try:
        # Load authority tables using their filenames as table names.
        for file in sorted(AUTHORITY_DIR.glob("*.psv")):
            table = authority_table_name(file.name)
            copy_file(conn, table, file)

        # Load state-specific files after removing their state prefix.
        for file in sorted(STANDARD_DIR.glob("*.psv")):
            table = state_table_name(file.name)
            copy_file(conn, table, file)

        print("Load complete")

    finally:
        # Close the connection even if a file fails to load.
        conn.close()


if __name__ == "__main__":
    main()
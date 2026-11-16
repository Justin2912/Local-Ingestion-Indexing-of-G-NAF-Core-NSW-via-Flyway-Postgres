from pathlib import Path
import pandas as pd 

# Folder containing the G-NAF standard data files.
gnaf_folder = Path("C:/Users/Justin.Lam/Desktop/GNAFAUGUST2026/Standard")


# Search subfolders for street/locality alias files.
psv_files = psv_files = list(gnaf_folder.glob("**/*STREET_LOCALITY_ALIAS_psv.psv"))

# Print the matching filenames, or report that none were found.
if not psv_files:
    print(
        "❌ No matching STREET_LOCALITY_ALIAS_psv.psv files found."
    )
else:
    print(f"✅ Found {len(psv_files)} matching files:")


    for file_path in psv_files:
        print(f"  - {file_path.name}")




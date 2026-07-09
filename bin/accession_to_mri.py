import argparse
import requests

BASE = "https://datasetcache.gnps2.org/datasette/database"

def fetch_usis(accession):
    url = f"{BASE}/filename.json"
    params = {"dataset": accession, "_size": "max", "_shape": "array"}

    usis = []
    while url:
        r = requests.get(url, params=params, timeout=60)
        r.raise_for_status()
        body = r.json()
        # _shape=array returns a list directly
        rows = body if isinstance(body, list) else body.get("rows", [])
        usis.extend(row["usi"] for row in rows)
        url = body.get("next_url") if isinstance(body, dict) else None
        params = None

    return usis

def main():
    parser = argparse.ArgumentParser(description="Generate MRI TSV from one or more dataset accessions via the GNPS2 dataset cache.")
    parser.add_argument("accession", help="Dataset accession, or several separated by semicolons (e.g. MSV000086206;MSV000086207)")
    parser.add_argument("output_file", help="Output TSV file path")
    args = parser.parse_args()

    accessions = [a.strip() for a in args.accession.split(";") if a.strip()]

    all_usis = []
    seen = set()
    for accession in accessions:
        usis = fetch_usis(accession)
        for usi in usis:
            if usi not in seen:
                seen.add(usi)
                all_usis.append(usi)
        print(f"Fetched {len(usis)} USIs for {accession}")

    with open(args.output_file, "w") as f:
        f.write("usi\n")
        for usi in all_usis:
            f.write(f"{usi}\n")

    print(f"Wrote {len(all_usis)} USIs for {len(accessions)} accession(s) to {args.output_file}")

if __name__ == "__main__":
    main()

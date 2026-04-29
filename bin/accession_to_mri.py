import argparse
import requests

BASE = "https://datasetcache.gnps2.org/datasette/database"

def main():
    parser = argparse.ArgumentParser(description="Generate MRI TSV from a dataset accession via the GNPS2 dataset cache.")
    parser.add_argument("accession", help="Dataset accession (e.g. MSV000086206)")
    parser.add_argument("output_file", help="Output TSV file path")
    args = parser.parse_args()

    url = f"{BASE}/filename.json"
    params = {"dataset": args.accession, "_size": "max", "_shape": "array"}

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

    with open(args.output_file, "w") as f:
        f.write("usi\n")
        for usi in usis:
            f.write(f"{usi}\n")

    print(f"Wrote {len(usis)} USIs for {args.accession} to {args.output_file}")

if __name__ == "__main__":
    main()

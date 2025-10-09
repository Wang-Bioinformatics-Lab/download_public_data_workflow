import pandas as pd
import argparse

def main():

    # parsing args
    parser = argparse.ArgumentParser(description="Filter out blacklisted datasets from a given MRI file.")
    parser.add_argument("input_mri_file", help="Input MRI file (tab-delimited).")
    parser.add_argument("output_filtered_file", required=True, help="Output file for filtered MRI data.")

    args = parser.parse_args()

    # Reading input file
    df = pd.read_csv(args.input_mri_file, sep="\t")

    blacklist_expressions = [
        "MSV000096802",
        "MSV000084856",
        "MSV000083532", #proteomics
    ]

    # Filtering out blacklisted datasets
    for expr in blacklist_expressions:
        df = df[~df['usi'].str.contains(expr)]

    # Writing output file
    df.to_csv(args.output_filtered_file, sep="\t", index=False)


if __name__ == "__main__":
    main()
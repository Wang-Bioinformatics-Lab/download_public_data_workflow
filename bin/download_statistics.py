import sys
import os
import csv
from collections import defaultdict
import argparse

# Define the prefixes of the data sources 
data_source_prefix = ["mzspec:MSV", "mzspec:ST", "mzspec:MTBLS"]

# Define all possible download status
status_list = ["DOWNLOADED_INTO_OUTPUT_WITHOUT_CACHE", "EXISTS_IN_OUTPUT", "ERROR"]

# Initialize counters for each status and prefix combination
counters = defaultdict(lambda: defaultdict(int))

# Function to process the input TSV file and count entries
def count_status_entries(input_file):
    with open(input_file, mode='r') as file:
        reader = csv.DictReader(file, delimiter='\t')
        for row in reader:
            usi = row['usi']
            status = row['status']
            #for prefix in prefix_status_mapping.keys():
            for prefix in data_source_prefix:
                if usi.startswith(prefix):
                    counters[prefix][status] += 1

# Function to write the results to an output TSV file with row and column totals
def write_output_file(output_file):
    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file, delimiter='\t')
        
        # Write header with additional "Total" column
        writer.writerow(['Status', 'MSV', 'ST', 'MTBLS', 'Row Total'])
        
        # Calculate and write each row of the table with totals
        #for status in prefix_status_mapping.values():
        for status in status_list:
            msv_count = counters["mzspec:MSV"].get(status, 0)
            st_count = counters["mzspec:ST"].get(status, 0)
            mtbls_count = counters["mzspec:MTBLS"].get(status, 0)
            row_total = msv_count + st_count + mtbls_count
            writer.writerow([status, msv_count, st_count, mtbls_count, row_total])
        
        # Calculate and write the column totals and grand total
        msv_total = sum(counters["mzspec:MSV"].values())
        st_total = sum(counters["mzspec:ST"].values())
        mtbls_total = sum(counters["mzspec:MTBLS"].values())
        grand_total = msv_total + st_total + mtbls_total
        writer.writerow(['Column Total', msv_total, st_total, mtbls_total, grand_total])

if __name__ == "__main__":
    # Check if the input file is provided as a command-line argument
    if len(sys.argv) != 3:
        print("Usage: python download_statistics.py <input_file.tsv> <out_put_folder>")
        sys.exit(1)

    parser = argparse.ArgumentParser(description='Running download_statistics')
    parser.add_argument('input_download_file', help='input download file, it is a tsv file with a usi header.')
    parser.add_argument('output_folder', help='Output Folder where the data goes')

    args = parser.parse_args()
    input_file = args.input_download_file 

    # checking the input file exists
    if not os.path.isfile(input_file):
        print(f"Input file {input_file} does not exist")
        exit(0)
    
    if not os.path.isdir(args.output_folder):
        os.makedirs(args.output_folder, exist_ok=True)

    # Define the output file name 
    output_file = os.path.join(args.output_folder, "download_summary_statistics.tsv")
    
    # Process the input file and write the output
    count_status_entries(input_file)
    write_output_file(output_file)
    
    print(f"Results with totals have been written to {output_file}")


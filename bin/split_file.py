import os
import argparse
import pandas as pd

def process_csv(input_file, lines_per_file, output_folder=None):
    # Determine the output folder
    if output_folder is None:
        output_folder = os.getcwd()
    else:
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)
    
    # Read the CSV file using pandas
    df = pd.read_csv(input_file, encoding='utf-8-sig')
    
    # Calculate the number of smaller files needed
    total_lines = len(df)
    num_files = (total_lines + lines_per_file - 1) // lines_per_file
    
    for file_count in range(num_files):
        start_index = file_count * lines_per_file
        end_index = min(start_index + lines_per_file, total_lines)
        
        # Extract the portion of the dataframe for the current file
        df_subset = df.iloc[start_index:end_index]
        
        # Generate the output file name
        output_file = os.path.join(output_folder, f'Split_{input_file}_{start_index + 1}-{end_index}.csv')
        
        # Write the subset to a new CSV file
        df_subset.to_csv(output_file, index=False, header=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Split a CSV file into smaller files based on the number of lines.')
    parser.add_argument('input_file', type=str, help='The path to the input CSV file.')
    parser.add_argument('lines_per_file', type=int, help='The number of lines per smaller file.')
    parser.add_argument('output_folder', nargs='?', default=None, help='The folder to store the smaller files. Defaults to the current working directory.')

    args = parser.parse_args()

    process_csv(args.input_file, args.lines_per_file, args.output_folder)

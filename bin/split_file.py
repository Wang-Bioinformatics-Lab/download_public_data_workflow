import csv
import os
import sys
'''
This program is designed to get the first colomn of a csv file and output them in smaller files
while keeping the same header of the first column in the original csv file.  Each smaller file 
will store the number of lines specified by a command line argument, and the smaller files are 
stored in an output folder specified by an optional third command line argument.  If the output
folder is not specified, then the smaller files will be stored in the current working directory
'''
def process_csv(input_file, lines_per_file, output_folder=None):
    # Determine the output folder
    if output_folder is None:
        output_folder = os.getcwd()
    else:
        if not os.path.exists(output_folder):
            os.makedirs(output_folder)

    # Read the CSV file
    with open(input_file, 'r', newline='', encoding='utf-8-sig') as csv_file:
        reader = csv.reader(csv_file)
        header = next(reader)  # Read the header
        first_column_header = header[0]  # Get the header of the first column

        current_lines = []
        file_count = 1
        current_line = 0

        # Helper function to write current lines to a file
        def write_current_lines(lines, file_count, start_line, end_line):
            output_file = os.path.join(output_folder, f'Split_{input_file}_{start_line}-{end_line}.csv')
            with open(output_file, 'w', newline='', encoding='utf-8') as out_file:
                writer = csv.writer(out_file)
                writer.writerow([first_column_header])  # Write the header
                writer.writerows(lines)

        for row in reader:
            if current_line == 0:
                current_lines.append([row[0]])  # Add header to the current lines
            else:
                current_lines.append([row[0]])

            current_line += 1

            # Write to smaller file when lines_per_file is reached
            if current_line % lines_per_file == 0:
                write_current_lines(current_lines, file_count, current_line - lines_per_file + 1, current_line)
                file_count += 1
                current_lines = []

        # Write the last batch of lines
        if current_lines:
            write_current_lines(current_lines, file_count, current_line - len(current_lines) + 1, current_line)

if __name__ == "__main__":
    # Check for correct number of command-line arguments
    if len(sys.argv) < 3 or len(sys.argv) > 4:
        print("Usage: python split_file.py input_file lines_per_file [output_folder]")
        sys.exit(1)

    input_file = sys.argv[1]
    lines_per_file = int(sys.argv[2])
    output_folder = sys.argv[3] if len(sys.argv) == 4 else None

    process_csv(input_file, lines_per_file, output_folder)


#!/bin/bash

# put <!--@embed:filepath:startline:endline--> in your markdown file
# startline and endline are optional

# Check if input file is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <input_markdown_file> <output_markdown_file>"
    exit 1
fi

input_file="$1"
output_file="$2"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: Input file '$input_file' does not exist"
    exit 1
fi

# Create a temporary file
temp_file=$(mktemp)

# Copy input to temp file
cp "$input_file" "$temp_file"

# Process the file
while IFS= read -r line || [ -n "$line" ]; do
    if [[ $line =~ \<\!--@embed:([^:]+)(:([0-9]+)?)?(:([0-9]+)?)?\-\-\> ]]; then

        filepath="${BASH_REMATCH[1]}"
        start_line="${BASH_REMATCH[3]}"
        end_line="${BASH_REMATCH[5]}"
        
        # Check if embedded file exists
        if [ ! -f "$filepath" ]; then
            echo "File '$filepath' not found" >&2
            exit 1
            continue
        fi
        
        # If start_line and end_line are specified, extract those lines
        if [ ! -z "$start_line" ] && [ ! -z "$end_line" ]; then
            sed -n "${start_line},${end_line}p" "$filepath"
        # If only start_line is specified, extract from that line to the end
        elif [ ! -z "$start_line" ]; then
            sed -n "${start_line},\$p" "$filepath"
        # If no lines specified, include entire file
        else
            cat "$filepath"
        fi
    else
        echo "$line"
    fi
done < "$input_file" > "$output_file"

# Clean up
rm "$temp_file"

echo "Processing complete. Output written to $output_file"
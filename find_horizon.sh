#!/bin/bash

# Check usage: expects one argument, the base directory
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <base_directory>"
    exit 1
fi

BASE_DIR="$1"

# Verify that the base directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "Error: Directory '$BASE_DIR' does not exist."
    exit 1
fi

# Change to the base directory
cd "$BASE_DIR" || exit 1

# Create the destination directory 'tst' if it doesn't exist
if [ ! -d "tst" ]; then
    mkdir tst
fi

# Automatically determine the maximum integer n among directories named "output_n"
max_n=$(for d in output_[0-9]*; do
    if [ -d "$d" ]; then
        num="${d#output_}"
        if [[ "$num" =~ ^[0-9]+$ ]]; then
            echo "$num"
        fi
    fi
done | sort -n | tail -1)

echo "Maximum output number found: $max_n"

# Loop through output_n directories in order from 1 to max_n
for (( n=1; n<=max_n; n++ )); do
    dir="output_$n"
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        
	# Copy all files (without assuming only one) from the directory into tst.
        for file in "$dir"/*; do
            cp "$file" tst/
        done
	
	pushd tst
	# Run the horizon finder command
        /global/homes/h/hzhu/ahfind/exe/cactus_einsteintoolkitanalysis ET_analyze_BHaH_data_horizon.par
        popd
    else
        echo "Warning: Directory $dir not found, skipping."
    fi
done


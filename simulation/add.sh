#!/bin/bash
rapidity=(2.9 3.0 3.1)

# Loop over all directories in the output folder
for num in "${rapidity[@]}"
do
    rapidity_dir=$(echo "$num" | tr '.' '_')
    echo "Processing rapidity: $num"
    for file in output/simbfc/eta_${rapidity_dir}/
    do
        for dir in $(find $file -mindepth 1 -maxdepth 1 -type d)
        do
            echo "Processing directory: $dir"
            subdir_name=$(basename "$dir")
            echo "Subdirectory name: $subdir_name"
            hadd -f ~/MuDst/input/track_qa/eta_"$rapidity_dir"/"$subdir_name".root "$dir"/Output/output_hadron*
        done
    done
done
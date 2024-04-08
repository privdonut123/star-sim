#!/bin/bash
mode="simflat"
energy_values=(30 45 60 75 90)
rapidity_low=2.9
rapidity_high=$(echo "$rapidity_low + 0.01" | bc)

# Replace decimal point with underscore
rapidity_low_dir=$(echo "$rapidity_low" | tr '.' '_')

# Adjust the rapidity in runSimFlat
sed -i $'51c\\\t\\\tkinematics->Kine(npart, PID, e-0.01, e+0.01, '"$rapidity_low"', '"$rapidity_high"', -pi, pi);' runSimFlat.C

# Adjust energy for runSimFlat and runSimBfc
for energy in "${energy_values[@]}"
do
    sed -i $''"166"'c\\'\t'push @DATAFILES, "$i pi- '"$energy"' 0 0 1";' MakeJobSimFlat.pl

    if [ "$mode" == "simflat" ]; then
    ./MakeJobSimFlat.pl -o "output/simflat/eta_${rapidity_low_dir}/" -m "$mode" -u pi-e"$energy" -w -e
    fi

    if [ "$mode" == "simbfc" ]; then
        ./MakeJobSimFlat.pl -d "output/simflat/eta_${rapidity_low_dir}/pi-e${energy}/" -o "output/simbfc/eta_${rapidity_low_dir}/" -m "$mode" -u pi-e"$energy" -w -e
    fi
done
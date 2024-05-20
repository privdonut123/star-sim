#!/bin/bash
mode="simbfc"
pid="mu-"
energy_values=(5 15 30 45 60 75 90)
rapidity_low=3.1
rapidity_high=$(echo "$rapidity_low + 0.01" | bc)

# Replace decimal point with underscore
rapidity_low_dir=$(echo "$rapidity_low" | tr '.' '_')

# Adjust the rapidity in runSimFlat
sed -i $'51c\\\t\\\tkinematics->Kine(npart, PID, e-0.01, e+0.01, '"$rapidity_low"', '"$rapidity_high"', -pi, pi);' runSimFlat.C

# Adjust energy for runSimFlat and runSimBfc
for energy in "${energy_values[@]}"
do
    sed -i $''"293"'c\\'\t'push @DATAFILES, "$i '"$pid"' '"$energy"' 0 0 1";' MakeJob.pl

    if [ "$mode" == "simflat" ]; then
    ./MakeJob.pl -o "output/simflat/eta_${rapidity_low_dir}/" -m "$mode" -u "$pid"e"$energy" -w -e
    fi

    if [ "$mode" == "simbfc" ]; then
        ./MakeJob.pl -d "output/simflat/eta_${rapidity_low_dir}/"$pid"e${energy}/Output" -o "output/simbfc/eta_${rapidity_low_dir}/" -m "$mode" -u "$pid"e"$energy" -w -e
    fi

    if [ "$mode" == "simflatbfc" ]; then
        ./MakeJob.pl -o "output/simflat/eta_${rapidity_low_dir}/" -m "$mode" -u "$pid"e"$energy" -w -e
    fi
done
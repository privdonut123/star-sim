#!/bin/bash
run_mode="run"

mode="simbfc"
# Array of particle IDs
pid_values=("pi-" "mu-")
# pid_values=("pi-")
energy_values=(1 2.5 5 7.5 12.5 15 30 45 60 75 90)
# energy_values=(45 60 75 90)
# energy_values=(5)
# Array of rapidity values
rapidity_values=(2.9 3.0 3.1)
# rapidity_values=(2.9)

if [ "$run_mode" == "run" ]; then
    # Loop over particle IDs
    for pid in "${pid_values[@]}"
    do
        # Loop over rapidity values
        for rapidity_low in "${rapidity_values[@]}"
        do
            rapidity_high=$(echo "$rapidity_low + 0.01" | bc)

            # Replace decimal point with underscore
            rapidity_low_dir=$(echo "$rapidity_low" | tr '.' '_')

            # Adjust the rapidity in runSimFlat
            sed -i $'51c\\\t\\\tkinematics->Kine(npart, PID, e-0.01, e+0.01, '"$rapidity_low"', '"$rapidity_high"', -pi, pi);' runSimFlat.C

            # Adjust energy for runSimFlat and runSimBfc
            for energy in "${energy_values[@]}"
            do
                sed -i $''"297"'c\\'\t'push @DATAFILES, "$i '"$pid"' '"$energy"' 0 0 1";' MakeJob.pl

                if [ "$mode" == "simflat" ]; then
                    ./MakeJob.pl -o "output/simflat/eta_${rapidity_low_dir}/" -m "$mode" -u "$pid"e"$energy" -w -e -f
                fi

                if [ "$mode" == "simbfc" ]; then
                    ./MakeJob.pl -d "output/simflat/eta_${rapidity_low_dir}/"$pid"e${energy}/Output" -o "output/simbfc/eta_${rapidity_low_dir}/" -m "$mode" -u "$pid"e"$energy" -w -e -f
                fi

                if [ "$mode" == "simflatbfc" ]; then
                    ./MakeJob.pl -o "output/test/" -m "$mode" -u "$pid"e"$energy" -w -e -t
                fi
            done
        done
    done
fi

if [ "$run_mode" == "test" ] ; then
    echo "Running in test mode for simbfc"
    pid_values="mu-"
    energy_values=30
    rapidity_values=2.0
    rapidity_high=4.5
    # rapidity_high=$(echo "$rapidity_values + 0.01" | bc)

    # Replace decimal point with underscore
    rapidity_low_dir=$(echo "$rapidity_values" | tr '.' '_')

    # Adjust the rapidity in runSimFlat
    sed -i $'51c\\\t\\\tkinematics->Kine(npart, PID, e-29, e+29, '"$rapidity_values"', '"$rapidity_high"', -pi, pi);' runSimFlat.C
    sed -i $''"359"'c\\'\t'push @DATAFILES, "$i '"$pid_values"' '"$energy_values"' 0 0 1";' MakeJob.pl
    if [ "$mode" == "simflat" ]; then
        ./MakeJob.pl -o "output/simflat/eta_${rapidity_low_dir}/" -m "$mode" -u "$pid_values"e"$energy_values" -w -e -n 10000
    fi
    if [ "$mode" == "simbfc" ]; then
        ./MakeJob.pl -d "output/simflat/eta_${rapidity_low_dir}/"$pid_values"e${energy_values}/Output" -o "output/test" -m "$mode" -u "$pid_values"e"$energy_values" -w -e -n 10000 
    fi
fi
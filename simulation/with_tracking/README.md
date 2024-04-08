# Simulation with forward tracking

How to setup
------------
Using the <i>stardev</i> enviroment, follow the instructions given [here](https://github.com/jdbrice/star-sw-1/wiki#accessing-up-to-date-code) to install the required libraries.

Single-particle simulation
--------------------------
To run a single-particle simulation, we can use the [runSimFlat.C](runSimFlat.C) and the [recon.C](recon.C) codes in this directory. To run 100 single negative muon events with muons at E = 30 GeV, eta = +3.0, and Vz = 0, do the following:
```
root4star -b -q 'runSimFlat.C(100,1,"mu-",30,0,0,1)'
```
This creates a ROOT file with the generated particles, as well as a <i>.fzd</i> file with the detector response information.

The events can then be reconstructed by doing
```
root4star -b -q 'recon.C(100,"StFwdTrackMaker_ideal_sim_ftt_seed.root", false, true, false,1,"mu-",30)'
```
This runs [ideal tracking with ftt seeding](https://github.com/jdbrice/fwd-software/wiki#ideal-tracking-use-truth-info). The output of this reconstruction will be a MuDST file, a <i>.event</i> file, and some QA ROOT files. The MuDST file can then be processed to create a simple ROOT TTree for further analysis:
```
root4star -b -q 'readMudst.C(0,1,"input/mu-.MuDst.root")'
```

To run using ideal tracking with <i>fst</i> seeding instead, do the following during the reconstruction step:
```
root4star -b -q 'recon.C(100,"StFwdTrackMaker_ideal_sim_fst_seed.root", true, true, false,1,"mu-",30)'
```

To run all simulation setting and create the simple tree for further analysis, use the [run_fast.sh](run_fast.sh) file in this directory.


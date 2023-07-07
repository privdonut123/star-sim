# STAR Simulation

Single-particle simulation
--------------------------
In progress...

Pythia8 simulation
------------------
To generate events and run those events through the STAR detector simulation, we use [this code](starsim.pythia8.C) and run as follows:
```
root4star -b -q 'starsim.C(1000)'
```
This creates a ROOT file with the generated particles and a <i>.fzd</i> file with the detector response information. The simulation can also be performed using the STAR scheduler:
```
star-submit starsim.xml
```

The events can then be reconstructed by doing
```
root4star -b -q 'runSimBfc.C(1000,1,"pythia")'
```
This creates a <i>.MuDST.root</i> file. The generated MuDST file can then be processed to create a simple ROOT TTree for further analysis:
```
root4star -b -q 'readMudst.C(0,1,"input/pythia8.MuDst.root")'
```

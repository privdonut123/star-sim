# STAR simulation job submission

To run 10 Pythia8 jobs with 1000 events each:
```
star-submit starsim.xml
```
For each job, the generated events ROOT file and the final compressed ROOT file for analysis will be written out to the requested folder. N.B. You will need to adjust the output directories in the .xml script to point to your own folder.

To run 10 Herwig6 jobs with 1000 events each:
```
star-submit starsim_herwig.xml
```

Note that the [runSimBfc.C](runSimBfc.C) in this directory has been modified a bit compared to the one in the parent directory. In particular, the MuDST file is no longer written out, since the compressed ROOT file is created directly in the code. The trigger libraries are also commented out.

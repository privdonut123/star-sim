# STAR simulation job submission

To run 10 jobs with 1000 events each:
```
star-submit starsim.xml
```
For each job, the generated events ROOT file and the final compressed ROOT file for analysis will be written. Note that the [runSimBfc.C](runSimBfc.C) in this directory has been modified a bit compared to the one in the parent directo particular, the MuDST file is no longer written out, since the compressed ROOT file is created directly in the code. The trigger libraries are also commented out. 

N.B. You will need to adjust the output directories in the .xml script to point to your own folder.

# star-analysis

Making a simple ROOT file for analysis
--------------------------------------
For a muDST file containing STAR forward upgrade data, we have two codes which can read the MuDST file and create a simple ROOT TTree.

1. Reading the muDST classes directly. This approach can be found in the macro [readMudst.C](readMudst.C).
   
   To run the macro on a single file, the following command can be used:
   ```
   root4star -b -q 'readMudst.C(0,1,"input/zfa_prod/st_physics_23072003_raw_1000002.MuDst.root")'
   ```
   To run the macro on a [file list](input/filelist.list), the following command can be used:
   ```
   root4star -b -q 'readMudst.C(0,5,"filelist.list")'
   ```
   
2. For the FCS, reading the time-dependent ADC signal and then using <i>StEvent</i> classes. This approach can be found in the macro [runMudst.C](runMudst.C).

   To run the macro on a single file, the following command can be used:
   ```
   root4star -b -q 'runMudst.C(0,1,"input/zfa_prod/st_physics_23072003_raw_1000002.MuDst.root")'
   ```

Simulation
----------
Information on running simulation studies is provided in the [simulation](simulation) subdirectory.

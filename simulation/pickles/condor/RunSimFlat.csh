    
#!/bin/csh

stardev
echo $STAR_LEVEL
#Getting rid of 'cd' Output file will no longer bin condor dir but where it is supposed to go
#cd /gpfs/mnt/gpfs01/star/pwg/bmagh001/star-sim/simulation/pickles/condor
#$1=number of events
#$2=run(seed)
#$3=pid as string
#$4=energy if==0 then use pt
#$5=pt if==0 then use energy
#$6=vz z-vertex
#$7=npart (number of particles)
echo "NumEvents:${1}\nRun:${2}\nPid:${3}\nEn:${4}\nPt:${5}\nVz:${6}\nNPart:${7}\n"
set fzdname = "$3.e$4.vz$6.run$2.fzd"
ls -a $PWD
echo "root4star -b -q runSimFlat.C'($1,$2,"\"${3}\"",$4,$5,$6,$7)'"
root4star -b -q runSimFlat.C'('$1','$2','\"$3\"','$4','$5','$6','$7')'

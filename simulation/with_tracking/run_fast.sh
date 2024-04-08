#!/usr/bin/bash

#N.B. STAR version should be DEV

nevents=${1:-10}
echo "Running $nevents events per setting."

energy=${2:-30}
echo "Running with ${energy} GeV negative muon."

#Set particle and associated running tag
particle=${3:-mu_minus}
echo "Running single ${particle} simulation."

if [ "${particle}" = "mu_minus" ]; then
    ptag=mu-
fi

echo "Particle tag is ${ptag}."
echo ""

#Single particle simulation ( eta = +3.0, vertex = (0,0,0) )
echo ""
echo "Starting Geant simulation"
root4star -b -q runSimFlat.C\(${nevents},1,\"${ptag}\",${energy},0,0,1\)

#Ideal ftt seeding
echo ""
echo "Starting ideal FTT seeded reconstruction"
root4star -b -q 'recon.C('${nevents}',"StFwdTrackMaker_ideal_sim_ftt_seed.root", false, true, false,1,"'${ptag}'",'${energy}')' \
| tee log/output_${ptag}_30_3_fttideal.dat

#Create simple ROOT file for analysis
echo ""
echo "Creating ROOT file for analysis"
root4star -b -q 'readMudst.C(0,1,"'${ptag}'.MuDst.root")'

#Move reconstruction files
output_dir=output/${particle}/${energy}GeV_eta3/ideal_ftt_seed/
mv ${ptag}.MuDst.root ${output_dir} #MuDST file
mv SimpleTree_mudst.root ${output_dir} #Created by my Maker
mv ${ptag}.e30.vz0.event.root ${output_dir} #Event file
mv fcstrk.root ${output_dir}  #Created by StFcsTrackMatchMaker
mv StFwdAnalysisMaker.root ${output_dir} #Created by StFwdAnalysisMaker
mv StFwdFitQAMaker.root ${output_dir} #Created by StFwdFitQAMaker
#mv StFwdTrackMaker_ideal_sim_ftt_seed.root ${output_dir} #Created if TrackMaker creates histograms
#mv fwdtree.root ${output_dir} #Created if TrackMaker creates TTree

#Ideal fst seeding
echo ""
echo "Starting ideal FST seeded reconstruction"
root4star -b -q 'recon.C('${nevents}',"StFwdTrackMaker_ideal_sim_fst_seed.root", true, true, false,1,"'${ptag}'",'${energy}')' \
| tee log/output_${ptag}_30_3_fstideal.dat

#Create simple ROOT file for analysis
echo ""
echo "Creating ROOT file for analysis"
root4star -b -q 'readMudst.C(0,1,"'${ptag}'.MuDst.root")'

#Move reconstruction files
output_dir=output/${particle}/${energy}GeV_eta3/ideal_fst_seed/
mv ${ptag}.MuDst.root ${output_dir} #MuDST file
mv SimpleTree_mudst.root ${output_dir} #Created by my Maker
mv ${ptag}.e30.vz0.event.root ${output_dir} #Event file
mv fcstrk.root ${output_dir}  #Created by StFcsTrackMatchMaker
mv StFwdAnalysisMaker.root ${output_dir} #Created by StFwdAnalysisMaker
mv StFwdFitQAMaker.root ${output_dir} #Created by StFwdFitQAMaker
#mv StFwdTrackMaker_ideal_sim_fst_seed.root ${output_dir} #Created if TrackMaker creates histograms
#mv fwdtree.root ${output_dir} #Created if TrackMaker creates TTree

#Realistic ftt seeding
echo ""
echo "Starting realistic FTT seeded reconstruction"
root4star -b -q 'recon.C('${nevents}',"StFwdTrackMaker_real_sim_ftt_seed.root", false, true, true,1,"'${ptag}'",'${energy}')' \
| tee log/output_${ptag}_30_3_fttreal.dat

#Create simple ROOT file for analysis
echo ""
echo "Creating ROOT file for analysis"
root4star -b -q 'readMudst.C(0,1,"'${ptag}'.MuDst.root")'

#Move reconstruction files
output_dir=output/${particle}/${energy}GeV_eta3/real_ftt_seed/
mv ${ptag}.MuDst.root ${output_dir} #MuDST file
mv SimpleTree_mudst.root ${output_dir} #Created by my Maker
mv ${ptag}.e30.vz0.event.root ${output_dir} #Event file
mv fcstrk.root ${output_dir}  #Created by StFcsTrackMatchMaker
mv StFwdAnalysisMaker.root ${output_dir} #Created by StFwdAnalysisMaker
mv StFwdFitQAMaker.root ${output_dir} #Created by StFwdFitQAMaker
#mv StFwdTrackMaker_real_sim_ftt_seed.root ${output_dir} #Created if TrackMaker creates histograms
#mv fwdtree.root ${output_dir} #Created if TrackMaker creates TTree

#Realistic fst seeding
echo ""
echo "Starting realistic FST seeded reconstruction"
root4star -b -q 'recon.C('${nevents}',"StFwdTrackMaker_real_sim_ftt_seed.root", true, true, true,1,"'${ptag}'",'${energy}')' \
| tee log/output_${ptag}_30_3_fstreal.dat

#Create simple ROOT file for analysis
echo ""
echo "Creating ROOT file for analysis"
root4star -b -q 'readMudst.C(0,1,"'${ptag}'.MuDst.root")'

#Move reconstruction files
output_dir=output/${particle}/${energy}GeV_eta3/real_fst_seed/
mv ${ptag}.MuDst.root ${output_dir} #MuDST file
mv SimpleTree_mudst.root ${output_dir} #Created by my Maker
mv ${ptag}.e30.vz0.event.root ${output_dir} #Event file
mv fcstrk.root ${output_dir}  #Created by StFcsTrackMatchMaker
mv StFwdAnalysisMaker.root ${output_dir} #Created by StFwdAnalysisMaker
mv StFwdFitQAMaker.root ${output_dir} #Created by StFwdFitQAMaker
#mv StFwdTrackMaker_real_sim_fst_seed.root ${output_dir} #Created if TrackMaker creates histograms
#mv fwdtree.root ${output_dir} #Created if TrackMaker creates TTree

#Move generated and Geant files
mv ${ptag}.e30.vz0.run1.fzd output/mu_minus/${energy}GeV_eta3/
mv ${ptag}.e30.vz0.run1.root output/mu_minus/${energy}GeV_eta3/

#Delete remaining ROOT files
rm -f ${ptag}.*.root

echo ""
echo "Done!"


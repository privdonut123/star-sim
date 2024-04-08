//usr/bin/env root4star -l -b -q $0'('$1')'; exit $?
// that is a valid shebang to run script as executable, but with only one arg

// Run very fast fwd tracking
// generate some input data using genfzd 

//TFile *output = 0;
TString input_dir   = "./";
TString output_dir  = "./";

void recon( int n = 5, // nEvents to run
            string outputName = "stFwdTrackMaker_ideal_sim.root",
            bool useFstForSeedFinding = false, // use FTT (default) or FST for track finding
            bool enableTrackRefit = true, // Enable track refit (default off)
            bool realisticSim = false, // enables data-like mode, real track finding and fitting without MC seed
            Int_t run=1, const char* pid="jet", int e=0, float vz=0.0,
	    TString myDir=input_dir, TString myOutDir=output_dir
          ) {

    //Input and output file names
    TString myDat; TString proc(pid);
    if(proc.Contains("dy") || proc.Contains("mb") || proc.Contains("jet") || proc.Contains("dybg")){
        myDat=Form("pythia.%s.vz%d.run%i.fzd",pid,(int)vz,run);
    }else if(proc.Contains("pythia8")){
        myDat="pythia8.starsim.fzd";
    }else if(proc.Contains("pythia6")){
        myDat = "pythia6.starsim.fzd";
    }else if(proc.Contains("herwig")){
        myDat = "herwig6.starsim.fzd";
    }else if(e>0.0){
        myDat=Form("%s.e%d.vz%d.run%i.fzd",pid,e,(int)vz,run);
    }else{
        myDat=Form("%s.pt%3.1f.vz%d.run%i.fzd",pid,pt,(int)vz,run);
    }

    TString infile = myDir+myDat;
    cout << "input file ="<<infile<<endl;
  
    TString outfile = myOutDir + myDat.ReplaceAll(".fzd",".root");      
    cout << "output file=" <<outfile<<endl;

    const char *geom = "y2023 agml usexgeom";
    TString _geom = geom;

    // Switches for common options 
    bool SiIneff = false;
    bool useConstBz = false;
    bool useFCS = true;

    // to use the geom cache (skip agml build which is faster)
    // set the _geom string to "" and make sure the cache file ("fGeom.root") is present
    // _geom = "";
    
    // Setup the chain for reading an FZD
    TString _chain;
    if ( useFCS )
        _chain = Form("fzin %s sdt20211016 fstFastSim fcsSim fcsWFF fcsCluster fwdTrack MakeEvent StEvent ReverseField bigbig evout cmudst tree", _geom.Data() );
    else 
        _chain = Form("fzin %s sdt20211016 MakeEvent StEvent ReverseField bigbig fstFastSim fcsSim fwdTrack evout cmudst tree", _geom.Data());

    gSystem->Load( "libStarRoot.so" );
    gROOT->SetMacroPath(".:/star-sw/StRoot/macros/:./StRoot/macros:./StRoot/macros/graphics:./StRoot/macros/analysis:./StRoot/macros/test:./StRoot/macros/examples:./StRoot/macros/html:./StRoot/macros/qa:./StRoot/macros/calib:./StRoot/macros/mudst:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/graphics:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/analysis:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/test:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/examples:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/html:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/qa:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/calib:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/mudst:/afs/rhic.bnl.gov/star/ROOT/36/5.34.38/.sl73_x8664_gcc485/rootdeb/macros:/afs/rhic.bnl.gov/star/ROOT/36/5.34.38/.sl73_x8664_gcc485/rootdeb/tutorials");

    gROOT->LoadMacro("bfc.C");
    bfc( -1, _chain, infile );
    chain->SetOutputFile(outfile);

    if ( useConstBz )
        StarMagField::setConstBz(true);

    gSystem->Load( "libStFttSimMaker" );
    gSystem->Load( "libStFcsTrackMatchMaker" );

    gSystem->Load( "libMathMore.so" );
    gSystem->Load( "libStarGeneratorUtil" );

    // FCS setup, if included
    if (useFCS) {

        StFcsDbMaker* fcsdbmkr = (StFcsDbMaker*) chain->GetMaker("fcsDbMkr");  
        cout << "fcsdbmkr="<<fcsdbmkr<<endl;
        StFcsDb* fcsdb = (StFcsDb*) chain->GetDataSet("fcsDb");  
        cout << "fcsdb="<<fcsdb<<endl;    
        //fcsdbmkr->setDbAccess(1);

        // Configure FCS simulator
        StFcsFastSimulatorMaker *fcssim = (StFcsFastSimulatorMaker*) chain->GetMaker("fcsSim");
        fcssim->setDebug(1);
        //fcssim->setLeakyHcal(0);

        StFcsWaveformFitMaker *fcsWFF= (StFcsWaveformFitMaker*) chain->GetMaker("StFcsWaveformFitMaker");
        fcsWFF->setEnergySelect(0);

        StFcsClusterMaker *fcsclu = (StFcsClusterMaker*) chain->GetMaker("StFcsClusterMaker");
        fcsclu->setDebug(1);
    }

        gSystem->Load("StFwdUtils.so");
	/*
         StFwdJPsiMaker *fwdJPsi = new StFwdJPsiMaker();
         fwdJPsi->SetDebug();
         chain->AddMaker(fwdJPsi);
         goto chain_loop;
	*/

        // Configure FST FastSim
        TString qaoutname(gSystem->BaseName(infile));
        qaoutname.ReplaceAll(".fzd", ".FastSimu.QA.root");
        StFstFastSimMaker *fstFastSim = (StFstFastSimMaker*) chain->GetMaker( "fstFastSim" );;

        if (SiIneff)
            fstFastSim->SetInEfficiency(0.1); // inefficiency of Si 

        fstFastSim->SetQAFileName(qaoutname);

        cout << "Adding StFstFastSimMaker to chain" << endl;
        chain->AddMaker(fstFastSim);


    // Configure the Forward Tracker
    StFwdTrackMaker * fwdTrack = (StFwdTrackMaker*) chain->GetMaker( "fwdTrack" );

    if ( fwdTrack ){
        // config file set here for ideal simulation
        if (!realisticSim){
            cout << "Configured for ideal simulation (MC finding + MC mom seed)" << endl;
            fwdTrack->setConfigForIdealSim( );
        } else {
            cout << "Configured for realistic simulation" << endl;
            fwdTrack->setConfigForRealisticSim( );
            cout << "Configured for realistic simulation DONE" << endl;
        }

        if ( _geom == "" ){
            cout << "Using the Geometry cache: fGeom.root" << endl;
            fwdTrack->setGeoCache( "fGeom.root" );
        }

        if (useFstForSeedFinding)
            fwdTrack->setSeedFindingWithFst();
        else
            fwdTrack->setSeedFindingWithFtt();

        fwdTrack->setTrackRefit( enableTrackRefit );
        fwdTrack->setOutputFilename( outputName );
        fwdTrack->SetGenerateTree( false );
        fwdTrack->SetGenerateHistograms( false );
        fwdTrack->SetDebug();

        StFwdFitQAMaker *fwdFitQA = new StFwdFitQAMaker();
        fwdFitQA->SetDebug();
        chain->AddAfter("fwdTrack", fwdFitQA);

        cout << "fwd tracker setup" << endl;
    }        

        if (!useFCS){
            StFwdAnalysisMaker *fwdAna = new StFwdAnalysisMaker();
            fwdAna->SetDebug();
            chain->AddAfter("fwdTrack", fwdAna);
        }

    StMuDstMaker * muDstMaker = (StMuDstMaker*)chain->GetMaker( "MuDst" );
    if (useFCS) {
        // FwdTrack and FcsCluster assciation
        gSystem->Load("StFcsTrackMatchMaker");
        StFcsTrackMatchMaker *match = new StFcsTrackMatchMaker();
        match->setMaxDistance(6,10);
        match->setFileName("fcstrk.root");
        match->SetDebug();
        chain->AddMaker(match);

        StFwdAnalysisMaker *fwdAna = new StFwdAnalysisMaker();
        fwdAna->SetDebug();
        chain->AddAfter("FcsTrkMatch", fwdAna);

        // Produce MuDst output
        chain->AddAfter( "FcsTrkMatch", muDstMaker );
    } else {
        chain->AddAfter( "fwdAna", muDstMaker );
    }

    
chain_loop:
	chain->Init();

    //_____________________________________________________________________________
    //
    // MAIN EVENT LOOP
    //_____________________________________________________________________________
    for (int i = 0; i < n; i++) {

        cout << "--------->START EVENT: " << i << endl;

        chain->Clear();
        if (kStOK != chain->Make())
            break;


        // StMuDst * mds = muDstMaker->muDst();
        // StMuFwdTrackCollection * ftc = mds->muFwdTrackCollection();
        // cout << "Number of StMuFwdTracks: " << ftc->numberOfFwdTracks() << endl;
        // for ( size_t iTrack = 0; iTrack < ftc->numberOfFwdTracks(); iTrack++ ){
        //     StMuFwdTrack * muFwdTrack = ftc->getFwdTrack( iTrack );
        //     cout << "muFwdTrack->mPt = " << muFwdTrack->momentum().Pt() << endl;

        // }

        cout << "<---------- END EVENT" << endl;
    } // event loop
}

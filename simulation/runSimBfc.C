TString input_dir   = "./";
TString output_dir  = "./";
//TString input_chain = "sdt20161210.120000,fzin,geant,evout,y2015,FieldOn,logger,MakeEvent,McEvout,IdTruth,ReverseField,db,fcsSim,fcsCluster,fcsPoint,-tpcDB";

//Default
//TString input_chain = "sdt20211025.120000,fzin,geant,FieldOn,logger,MakeEvent,fcsSim,fcsWFF,fcsCluster,fcsPoint";

//Weibin's setting
TString input_chain = "y2023,AgML,USExgeom,db,fzin,geant,FieldOn,StEvent,logger,MakeEvent,MuDST,fcsSim,cmudst,fcs,fst,ftt,fstFastSim,fwdTrack";
//_chain = Form("in, %s, useXgeom, AgML, db, StEvent, MakeEvent, MuDST, trgd, btof, fcs, fst, ftt, fttQA, fstMuRawHit, fwdTrack, evout, cmudst, tree", geom);
class StFmsSimulatorMaker;

void runSimBfc( Int_t nEvents=1000, Int_t run=1, const char* pid="jet", int TrgVersion=202207,
		int debug=0, int e=0, float pt=1.5, float vz=0.0,
		char* epdmask="0.0100",
		int leakyHcal=0, 
		int eventDisplay=0,
		TString myDir=input_dir, TString myOutDir=output_dir,
		TString myChain=input_chain, Int_t mnEvents=0){

  gROOT->SetMacroPath(".:/star-sw/StRoot/macros/:./StRoot/macros:./StRoot/macros/graphics:./StRoot/macros/analysis:./StRoot/macros/test:./StRoot/macros/examples:./StRoot/macros/html:./StRoot/macros/qa:./StRoot/macros/calib:./StRoot/macros/mudst:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/graphics:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/analysis:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/test:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/examples:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/html:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/qa:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/calib:/afs/rhic.bnl.gov/star/packages/DEV/StRoot/macros/mudst:/afs/rhic.bnl.gov/star/ROOT/36/5.34.38/.sl73_x8664_gcc485/rootdeb/macros:/afs/rhic.bnl.gov/star/ROOT/36/5.34.38/.sl73_x8664_gcc485/rootdeb/tutorials");

  gROOT->LoadMacro("bfc.C");
  //gSystem->Load( "StFttSimMaker" );
  //gSystem->Load( "libStFcsTrackMatchMaker" );
  gSystem->Load( "libMathMore.so" );
    //gSystem->Load( "libStarGeneratorUtil" );
  //  gROOT->Macro("loadMuDst.C");
  TString myDat;
  TString proc(pid);
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

  printf("Opening %s\n",(myDir+myDat).Data());
  bfc( -1, myChain, myDir+myDat );
 
  TString outfile = myOutDir + myDat.ReplaceAll(".fzd",".root");      
  cout << "output file=" <<outfile<<endl;
  chain->SetOutputFile(outfile);
  
  St_db_Maker *dbMk= (St_db_Maker*) chain->GetMaker("db");
  dbMk->SetAttr("blacklist", "tpc");
  dbMk->SetAttr("blacklist", "svt");
  dbMk->SetAttr("blacklist", "ssd");
  dbMk->SetAttr("blacklist", "ist");
  dbMk->SetAttr("blacklist", "pxl");
  dbMk->SetAttr("blacklist", "pp2pp");
  dbMk->SetAttr("blacklist", "ftpc");
  dbMk->SetAttr("blacklist", "emc");
  dbMk->SetAttr("blacklist", "eemc");
  dbMk->SetAttr("blacklist", "mtd");
  dbMk->SetAttr("blacklist", "pmd");
  dbMk->SetAttr("blacklist", "tof");
  dbMk->SetAttr("blacklist", "etof");
  dbMk->SetAttr("blacklist", "rhicf");
  dbMk->SetAttr("blacklist", "Calibrations_rich");

  StFcsDbMaker* fcsdbmkr = (StFcsDbMaker*) chain->GetMaker("fcsDbMkr");  
  cout << "fcsdbmkr="<<fcsdbmkr<<endl;
  fcsdbmkr->setDbAccess(1);

  StFcsDb* fcsdb = (StFcsDb*) chain->GetDataSet("fcsDb");  
  cout << "fcsdb="<<fcsdb<<endl;
  //fcsdb->readGainFromText();
  //fcsdb->readGainCorrFromText();
  fcsdb->forceUniformGain(0.0053);
  fcsdb->forceUniformGainCorrection(1.0);

  StFcsFastSimulatorMaker *fcssim = (StFcsFastSimulatorMaker*) chain->GetMaker("fcsSim");
  fcssim->setDebug(1);
  //fcssim->setLeakyHcal(leakyHcal);

  StFcsWaveformFitMaker *wff=(StFcsWaveformFitMaker *)chain->GetMaker("StFcsWaveformFitMaker");
  wff->setDebug(1);
  wff->setEnergySelect(0);

  //gSystem->Load("StFcsClusterMaker");
  StFcsClusterMaker *clu=(StFcsClusterMaker *)chain->GetMaker("StFcsClusterMaker");
  clu->setTowerEThreSeed(0.1,1.0);
  clu->setDebug(1);

  StFcsPointMaker *poi=(StFcsPointMaker *)chain->GetMaker("StFcsPointMaker");
  poi->setDebug(1);
  poi->setShowerShape(3);

  StFstFastSimMaker *fstFastSim = (StFstFastSimMaker*) chain->GetMaker( "fstFastSim" );
  chain->AddMaker(fstFastSim);
    

  cout << "Loading in StFwdTrackMaker..." << endl;
  StFwdTrackMaker *fwdTrack = (StFwdTrackMaker*) chain->GetMaker("fwdTrack");
    if ( fwdTrack ){ //if it is in the chain
        fwdTrack->setConfigForIdealSim( );
        fwdTrack->setSeedFindingWithFst();
        fwdTrack->SetGenerateTree( true );
        fwdTrack->SetGenerateHistograms( true );
        // write out wavefront OBJ files
        //fwdTrack->SetVisualize( false );
        fwdTrack->SetDebug();
    }

gSystem->Load("StKumMaker.so");
  StHadronAnalysisMaker* Hello = new StHadronAnalysisMaker();
  TString out_file=Form("output_hadron_%s_e%d_vz%d_run%i.root",pid,e,(int)vz,run);
  Hello->set_outputfile(out_file.Data());
    Hello->setDebug(1);
    chain->AddMaker(Hello);
    cout << out_file.Data() << endl;
  /*
  gSystem->Load("RTS");
  gSystem->Load("StFcsTriggerSimMaker");
  StFcsTriggerSimMaker* fcsTrgSim = new StFcsTriggerSimMaker(); 
  fcsTrgSim->setSimMode(1);
  fcsTrgSim->setTrigger(TrgVersion);
  fcsTrgSim->setDebug(debug);
  fcsTrgSim->setEtGain(1.0); //ET match
  //fcsTrgSim->setEtGain(0.5); //halfway
  //fcsTrgSim->setEtGain(0.0); //E match
  //fcsTrgSim->setReadPresMask(Form("mask/fcs_ecal_epd_mask.ele.pt0.6.vz0.thr%s.txt",epdmask));
  //TString txfile(outfile); txfile.ReplaceAll(".root",".event.txt");  fcsTrgSim->setWriteEventText(txfile.Data());
  TString qafile(outfile); qafile.ReplaceAll(".root",".qahist.root"); fcsTrgSim->setWriteQaHist(qafile.Data());
  fcsTrgSim->setThresholdFile("stage_params.txt");

  gSystem->Load("StFcsTrgQaMaker");
  StFcsTrgQaMaker* fcsTrgQa = new StFcsTrgQaMaker(); 
  TString tqafile(outfile); tqafile.ReplaceAll(".root",Form(".thr%s.trgqa.root",epdmask)); 
  fcsTrgQa->setFilename(tqafile.Data());
  fcsTrgQa->setEcalPtThr(pt*0.75);
  */

  if(eventDisplay>0){
      gSystem->Load("StEpdUtil");
      gSystem->Load("StFcsEventDisplay");
      StFcsEventDisplay* fcsed = new StFcsEventDisplay();
      fcsed->setMaxEvents(eventDisplay);
      outfile.ReplaceAll(".root",".eventDisplay.png");
      fcsed->setFileName(outfile.Data());
  }

  chain->Init();
  StMaker::lsMakers(chain);
  chain->EventLoop(mnEvents,nEvents);  
  chain->Finish(); 
}

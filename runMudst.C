void runMudst(Int_t nEvents, Int_t nFiles, TString InputFileList, char* outdir=".", int readMuDst=1, int debug=0){  
    gROOT->Macro("Load.C");
    gROOT->Macro("$STAR/StRoot/StMuDSTMaker/COMMON/macros/loadSharedLibraries.C");
    gSystem->Load("StEventMaker");
    gSystem->Load("StFcsDbMaker");
    gSystem->Load("StFcsRawHitMaker");
    gSystem->Load("StFcsWaveformFitMaker");
    gSystem->Load("StFcsClusterMaker");
    gSystem->Load("libMinuit");
    gSystem->Load("StFcsPointMaker");
    gSystem->Load("StEpdUtil");

    //gMessMgr->SetLimit("I", 0);
    //gMessMgr->SetLimit("Q", 0);
    //gMessMgr->SetLimit("W", 0);

    StChain* chain = new StChain("StChain"); chain->SetDEBUG(0);
    StMuDstMaker* muDstMaker = new StMuDstMaker(0, 0, "", InputFileList,".", nFiles, "MuDst");
    
    St_db_Maker* dbMk = new St_db_Maker("db","MySQL:StarDb","$STAR/StarDb"); 
    if(dbMk){
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
    }
    
    StFcsDbMaker *fcsDbMkr= new StFcsDbMaker();
    //StFcsDb* fcsDb = (StFcsDb*) chain->GetDataSet("fcsDb");
    //fcsDb->setReadGainFromText();
    //fcsDb->setReadGainCorrFromText();
   
    StEventMaker* eventMk = new StEventMaker();
    
    StFcsRawHitMaker* hit = new StFcsRawHitMaker();  
    hit->setReadMuDst(readMuDst);
   
    StFcsWaveformFitMaker *wff= new StFcsWaveformFitMaker();
    wff->setEnergySelect(13,13,1); //wff->setEnergySelect(10); //Default is (10,10,1)
    wff->setMaxPeak(8);
    wff->SetDebug(debug);

    //StFcsClusterMaker *clu= new StFcsClusterMaker();
    //StFcsPointMaker *poi= new StFcsPointMaker();
    //clu->SetDebug(debug);
    //poi->SetDebug(debug);

    //gSystem->Load("StVpdCalibMaker");
    //StVpdCalibMaker *vpdCalib = new StVpdCalibMaker();
    //vpdCalib->setMuDstIn();

    gSystem->Load("SimpleTree");
    SimpleTree* AnalysisCode = new SimpleTree();
    AnalysisCode->SetOutputFileName("SimpleTree.root");
    if ( nEvents == 0 )  nEvents = 10000000 ;       // Take all events in nFiles if nEvents = 0

    chain->Init();
    chain->EventLoop(1,nEvents);
    chain->Finish();
    delete chain;
}

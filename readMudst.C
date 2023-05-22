void readMudst(Int_t nEvents, Int_t nFiles, TString InputFileList, TString OutputDir =".", TString JobIdName = "" )
{

  // Load libraries
  gROOT   -> Macro("loadMuDst.C");
  gROOT   -> Macro("Load.C");
  gSystem -> Load("StFcsDbMaker");
  gSystem -> Load("SimpleReaderMaker.so");

  // List of member links in the chain
  StChain*                    chain  =  new StChain ;
  StMuDstMaker*          muDstMaker  =  new StMuDstMaker(0,0,"",InputFileList,"MuDst",nFiles) ;
 
  // Load the DB Maker
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
    
  StFcsDbMaker *fcsDbMkr = new StFcsDbMaker();

  //Analysis Maker
  SimpleReaderMaker* AnalysisCode  =  new SimpleReaderMaker(muDstMaker) ;

  // Turn off everything but FCS Hits in order to speed up the analysis and eliminate IO
  muDstMaker -> SetStatus("*",0) ;                // Turn off all branches
  muDstMaker -> SetStatus("MuEvent",1) ;          // Turn on the Event data (esp. Event number)
  muDstMaker -> SetStatus("FcsHit",1) ;           // Turn on the FCS Hit data

  // Miscellaneous things we need before starting the chain
  //TString Name = JobIdName ; //Name.Append(".histograms.root") ;
  AnalysisCode -> SetOutputFileName("SimpleTree_mudst.root") ; // Name the output file for histograms
  if ( nEvents == 0 )  nEvents = 10000000 ;       // Take all events in nFiles if nEvents = 0

  // Loop over the links in the chain
  chain -> Init() ;
  chain -> EventLoop(1,nEvents) ;
  chain -> Finish() ;

  // Cleanup
  delete chain ;
}

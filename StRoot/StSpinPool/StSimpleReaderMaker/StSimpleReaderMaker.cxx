// Class StSimpleReaderMaker

#include "StSimpleReaderMaker.h"

#include <iostream>

#include "StMuDSTMaker/COMMON/StMuDst.h"
#include "StMuDSTMaker/COMMON/StMuDstMaker.h"
#include "StMuDSTMaker/COMMON/StMuFcsHit.h"
#include "StMuDSTMaker/COMMON/StMuFcsCollection.h"
#include "StMuDSTMaker/COMMON/StMuMcTrack.h"
#include "StMuDSTMaker/COMMON/StMuMcVertex.h"
#include "StMuDSTMaker/COMMON/StMuEvent.h"
#include "StMuDSTMaker/COMMON/StMuFwdTrack.h"

#include "StFcsDbMaker/StFcsDbMaker.h"
#include "StFcsDbMaker/StFcsDb.h"

#include "StRoot/StEpdUtil/StEpdGeom.h"

#include "TTree.h"
#include "TFile.h"
#include "TObjArray.h"
#include "TClonesArray.h"

ClassImp(StSimpleReaderMaker)                   // Macro for CINT compatibility

StSimpleReaderMaker::StSimpleReaderMaker( StMuDstMaker* maker ) : StMaker("StSimpleReaderMaker")
{ // Initialize and/or zero all public/private data members here.
  out_file = NULL;
  out_tree = NULL;
  mOutputFileName = "";
  mEventsProcessed = 0;

  mEpdgeo = new StEpdGeom;  // EPD geom.

  mMuDstMaker = maker ;     // Pass MuDst pointer to DstAnlysisMaker Class member functions
}

StSimpleReaderMaker::~StSimpleReaderMaker() 
{ // Destroy and/or zero out all public/private data members here.
}

Int_t StSimpleReaderMaker::Init( )
{ // Do once at the start of the analysis

  // FCS DB
  mFcsDb = static_cast<StFcsDb*>(GetDataSet("fcsDb"));
  // mFcsDb->setDbAccess(0);
  if (!mFcsDb) {
  	LOG_ERROR << "StSimpleReaderMaker::InitRun Failed to get StFcsDb" << endm;
        return kStFatal;
  }

  out_file = new TFile(mOutputFileName,"RECREATE");
  out_tree = new TTree("data","Simple Data Tree");

  out_tree->Branch("Cal_nhits",&Cal_nhits,"Cal_nhits/I");
  out_tree->Branch("Cal_detid",Cal_detid,"Cal_detid[Cal_nhits]/I");
  out_tree->Branch("Cal_hitid",Cal_hitid,"Cal_hitid[Cal_nhits]/I");
  out_tree->Branch("Cal_adcsum",Cal_adcsum,"Cal_adcsum[Cal_nhits]/I");
  out_tree->Branch("Cal_hit_energy",Cal_hit_energy,"Cal_hit_energy[Cal_nhits]/F");
  out_tree->Branch("Cal_hit_posx",Cal_hit_posx,"Cal_hit_posx[Cal_nhits]/F");
  out_tree->Branch("Cal_hit_posy",Cal_hit_posy,"Cal_hit_posy[Cal_nhits]/F");
  out_tree->Branch("Cal_hit_posz",Cal_hit_posz,"Cal_hit_posz[Cal_nhits]/F");

  out_tree->Branch("Cal_nclus",&Cal_nclus,"Cal_nclus/I");
  out_tree->Branch("Cal_clus_detid",Cal_clus_detid,"Cal_clus_detid[Cal_nclus]/I");
  out_tree->Branch("Cal_clus_ntowers",Cal_clus_ntowers,"Cal_clus_ntowers[Cal_nclus]/I");
  out_tree->Branch("Cal_clus_energy",Cal_clus_energy,"Cal_clus_energy[Cal_nclus]/F");
  out_tree->Branch("Cal_clus_x",Cal_clus_x,"Cal_clus_x[Cal_nclus]/F");
  out_tree->Branch("Cal_clus_y",Cal_clus_y,"Cal_clus_y[Cal_nclus]/F");
  out_tree->Branch("Cal_clus_z",Cal_clus_z,"Cal_clus_z[Cal_nclus]/F");
	
  out_tree->Branch("Trk_ntrks",&Trk_ntrks,"Trk_ntrks/I");
  out_tree->Branch("Trk_px",Trk_px,"Trk_px[Trk_ntrks]/F");
  out_tree->Branch("Trk_py",Trk_py,"Trk_py[Trk_ntrks]/F");
  out_tree->Branch("Trk_pz",Trk_pz,"Trk_pz[Trk_ntrks]/F");
  out_tree->Branch("Trk_charge",Trk_charge,"Trk_charge[Trk_ntrks]/I");
  out_tree->Branch("Trk_chi2",Trk_chi2,"Trk_chi2[Trk_ntrks]/F");
  out_tree->Branch("Trk_ndf",Trk_ndf,"Trk_ndf[Trk_ntrks]/F");
  out_tree->Branch("Trk_proj_ecal_x",Trk_proj_ecal_x,"Trk_proj_ecal_x[Trk_ntrks]/F");
  out_tree->Branch("Trk_proj_ecal_y",Trk_proj_ecal_y,"Trk_proj_ecal_y[Trk_ntrks]/F");
  out_tree->Branch("Trk_proj_ecal_z",Trk_proj_ecal_z,"Trk_proj_ecal_z[Trk_ntrks]/F");
  out_tree->Branch("Trk_proj_hcal_x",Trk_proj_hcal_x,"Trk_proj_hcal_x[Trk_ntrks]/F");
  out_tree->Branch("Trk_proj_hcal_y",Trk_proj_hcal_y,"Trk_proj_hcal_y[Trk_ntrks]/F");
  out_tree->Branch("Trk_proj_hcal_z",Trk_proj_hcal_z,"Trk_proj_hcal_z[Trk_ntrks]/F");

  out_tree->Branch("mcpart_num",&mcpart_num,"mcpart_num/I");
  out_tree->Branch("mcpart_index",mcpart_index,"mcpart_index[mcpart_num]/I");
  out_tree->Branch("mcpart_geid",mcpart_geid,"mcpart_geid[mcpart_num]/I");
  out_tree->Branch("mcpart_idVtx",mcpart_idVtx,"mcpart_idVtx[mcpart_num]/I");
  out_tree->Branch("mcpart_px",mcpart_px,"mcpart_px[mcpart_num]/F");
  out_tree->Branch("mcpart_py",mcpart_py,"mcpart_py[mcpart_num]/F");
  out_tree->Branch("mcpart_pz",mcpart_pz,"mcpart_pz[mcpart_num]/F");
  out_tree->Branch("mcpart_E",mcpart_E,"mcpart_E[mcpart_num]/F");
  out_tree->Branch("mcpart_charge",mcpart_charge,"mcpart_charge[mcpart_num]/I");
  out_tree->Branch("mcpart_Vtx_x",mcpart_Vtx_x,"mcpart_Vtx_x[mcpart_num]/F");
  out_tree->Branch("mcpart_Vtx_y",mcpart_Vtx_y,"mcpart_Vtx_y[mcpart_num]/F");
  out_tree->Branch("mcpart_Vtx_z",mcpart_Vtx_z,"mcpart_Vtx_z[mcpart_num]/F");

  return kStOK ; 

}

Int_t StSimpleReaderMaker::Make( ) 
{ // Do each event

  // Reset variables
  Cal_nhits = 0; Cal_nclus = 0; mcpart_num = 0;

  // -----------
  // Get 'event' data 
  //StMuEvent* muEvent = mMuDstMaker->muDst()->event() ;

  // -----------
  // Get FCS data
  StMuFcsCollection* fcs_coll = mMuDstMaker->muDst()->muFcsCollection();  // Array containing the FCS Hits and Clusters

  // Loop over FCS hits
  for(UInt_t ihit = 0 ; ihit < fcs_coll->numberOfHits() ; ihit++){

  	StMuFcsHit* hit = fcs_coll->getHit(ihit); // Pointer to a hit
	
	int det = hit->detectorId();

        if( det < kFcsNDet ){ // Some entries in MuDST file have detid > 5
    
    		Cal_detid[Cal_nhits] = det;
   		Cal_hitid[Cal_nhits] = hit->id();
    		Cal_adcsum[Cal_nhits] = hit->adcSum();
    		Cal_hit_energy[Cal_nhits] = hit->energy();

		if( det <= kFcsHcalSouthDetId ){
        		StThreeVectorD xyz = mFcsDb->getStarXYZ(det,hit->id());

    			Cal_hit_posx[Cal_nhits] = xyz.x();
    			Cal_hit_posy[Cal_nhits] = xyz.y();
    			Cal_hit_posz[Cal_nhits] = xyz.z();
		}
	      	else if(det==kFcsPresNorthDetId || det==kFcsPresSouthDetId){ // EPD as Pres.
			// Adapted from code StFcsEventDisplay.cxx
			double zepd=375.0;
			double zfcs=710.0+13.90+15.0;
			double zr=zfcs/zepd;
			int pp,tt,n;
			double x[5],y[5];
			double xsum(0), ysum(0);
	       	 	mFcsDb->getEPDfromId(det,hit->id(),pp,tt);
			mEpdgeo->GetCorners(100*pp+tt,&n,x,y);
 		
			// Get average of corner positions
			// N.B. Number of corners is usually 4, sometimes 5	
			for(int i=0; i<n; i++){
			    xsum += zr*x[i];
			    ysum += zr*y[i];
			}
			Cal_hit_posx[Cal_nhits] = xsum/n;
                	Cal_hit_posy[Cal_nhits] = ysum/n;
                	Cal_hit_posz[Cal_nhits] = zepd;
	    	}
		// Increment number of hits
		Cal_nhits++;
	}
  } // Loop over FCS hits

  // Loop over FCS clusters
  for(UInt_t iclus = 0 ; iclus < fcs_coll->numberOfClusters() ; iclus++){

        StMuFcsCluster* clus = fcs_coll->getCluster(iclus); // Pointer to a cluster

	int det = clus->detectorId();

        if( det < kFcsNDet ){ // Some entries in MuDST file have detid > 5

		Cal_clus_detid[Cal_nclus] = det;
		Cal_clus_ntowers[Cal_nclus] = clus->nTowers();
		Cal_clus_energy[Cal_nclus] = clus->energy();

		// Get cluster global position
		StThreeVectorD xyz = mFcsDb->getStarXYZfromColumnRow(det,clus->x(),clus->y());
		Cal_clus_x[Cal_nclus] = xyz.x();
		Cal_clus_y[Cal_nclus] = xyz.y();
		Cal_clus_z[Cal_nclus] = xyz.z();

		// Increment number of clusters
		Cal_nclus++;
	}
  } // Loop over FCS clusters

  // -----------
  // Get Fwd track data
  StMuFwdTrackCollection * ftc = mMuDstMaker->muDst()->muFwdTrackCollection();
  Trk_ntrks = ftc->numberOfFwdTracks();
  
  for ( size_t iTrack = 0; iTrack < ftc->numberOfFwdTracks(); iTrack++ ){

	StMuFwdTrack * muFwdTrack = ftc->getFwdTrack( iTrack );

	Trk_px[iTrack] = muFwdTrack->momentum().Px();
	Trk_py[iTrack] = muFwdTrack->momentum().Py();
	Trk_pz[iTrack] = muFwdTrack->momentum().Pz();
 	Trk_charge[iTrack] = muFwdTrack->charge();
  	Trk_chi2[iTrack] = muFwdTrack->chi2();
  	Trk_ndf[iTrack] = muFwdTrack->ndf();

	// Set track projections to large negative values initially
	// in case track projection fails
	Trk_proj_ecal_x[iTrack] = -9999.;
	Trk_proj_ecal_y[iTrack] = -9999.;
	Trk_proj_ecal_z[iTrack] = -9999.;
	Trk_proj_hcal_x[iTrack] = -9999.;
        Trk_proj_hcal_y[iTrack] = -9999.;
        Trk_proj_hcal_z[iTrack] = -9999.;

	// Get track projections
	for ( auto proj : muFwdTrack->mProjections ) {
		// FCS ECal
		if (proj.mDetId == 41) { // See StEvent/StDetectorDefinitions.h
			Trk_proj_ecal_x[iTrack] = proj.mXYZ.x();
			Trk_proj_ecal_y[iTrack] = proj.mXYZ.y();
			Trk_proj_ecal_z[iTrack] = proj.mXYZ.z();
		}
		// FCS HCal
		if (proj.mDetId == 42) { // See StEvent/StDetectorDefinitions.h
                        Trk_proj_hcal_x[iTrack] = proj.mXYZ.x();
                        Trk_proj_hcal_y[iTrack] = proj.mXYZ.y();
                        Trk_proj_hcal_z[iTrack] = proj.mXYZ.z();
                }
	} // Loop over track projections

  } // Loop over Fwd tracks

  // -----------
  // Retrieve pointer to MC tracks
  TClonesArray *mcTracks = mMuDstMaker->muDst()->mcArray(1);
  
  // Loop over MC tracks
  for (Int_t iTrk=0; iTrk<mcTracks->GetEntriesFast(); iTrk++) {
	// Retrieve i-th MC tracks from MuDst
  	StMuMcTrack *mcTrack = (StMuMcTrack*)mcTracks->UncheckedAt(iTrk);

	if ( !mcTrack ) continue;

	mcpart_index[mcpart_num] = mcTrack->Id();
	mcpart_geid[mcpart_num] = mcTrack->GePid();
  	mcpart_idVtx[mcpart_num] = mcTrack->IdVx();  // ID of creation vertex
  	mcpart_px[mcpart_num] = mcTrack->Pxyz().x();
  	mcpart_py[mcpart_num] = mcTrack->Pxyz().y();
  	mcpart_pz[mcpart_num] = mcTrack->Pxyz().z();
  	mcpart_E[mcpart_num] = mcTrack->E();
  	mcpart_charge[mcpart_num] = mcTrack->Charge();

	// Find associated creation vertex
	// Retrieve pointer to MC vertices
	TClonesArray *mcVertices = mMuDstMaker->muDst()->mcArray(0);
	
	// Loop over MC vertices
	for (Int_t iVtx=0; iVtx<mcVertices->GetEntriesFast(); iVtx++) {

    		// Retrieve i-th MC vertex from MuDst
    		StMuMcVertex *mcVertex = (StMuMcVertex*)mcVertices->UncheckedAt(iVtx);
	
		if ( mcVertex->Id()==mcTrack->IdVx() ) {
			mcpart_Vtx_x[mcpart_num] = mcVertex->XyzV().x();	
			mcpart_Vtx_y[mcpart_num] = mcVertex->XyzV().y();
			mcpart_Vtx_z[mcpart_num] = mcVertex->XyzV().z();
		}
	} // Loop over MC vertices

	// Increment number of MC tracks
	mcpart_num++;

  } // Loop over MC tracks

  mEventsProcessed++ ;
  
  // Fill TTree
  out_tree->Fill();
  return kStOK ;
  
}

Int_t StSimpleReaderMaker::Finish( )
{ // Do once at the end the analysis

  out_file->Write();
  out_file->Close();

  cout << "Total Events Processed in DstMaker " << mEventsProcessed << endl ;

  return kStOk ;  

}

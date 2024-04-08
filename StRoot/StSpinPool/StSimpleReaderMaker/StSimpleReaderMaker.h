//Class StSimpleReaderMaker

#ifndef StSimpleReaderMaker_def
#define StSimpleReaderMaker_def

#include "StMaker.h"
#include "TString.h"

class StMuDstMaker ;
class TFile        ;
class TTree        ;
class StFcsDb      ;
class StEpdGeom    ;

class StSimpleReaderMaker : public StMaker
{
  
 private:

  StMuDstMaker* mMuDstMaker ;                      //  Make MuDst pointer available to member functions
  StFcsDb* mFcsDb = 0 ;
  StEpdGeom* mEpdgeo = 0 ;

  //Output file and tree
  TFile* out_file;
  TTree* out_tree;
  TString mOutputFileName;

  UInt_t        mEventsProcessed ;                 //  Number of Events read and processed

  //TTree Branch variables
  int Cal_nhits;
  int Cal_detid[5000];
  int Cal_hitid[5000];
  int Cal_adcsum[5000];
  float Cal_hit_energy[5000];
  float Cal_hit_posx[5000];
  float Cal_hit_posy[5000];
  float Cal_hit_posz[5000];

  int Cal_nclus;
  int Cal_clus_detid[1000];
  int Cal_clus_ntowers[1000];
  float Cal_clus_energy[1000];
  float Cal_clus_x[1000];
  float Cal_clus_y[1000];
  float Cal_clus_z[1000];

  int Trk_ntrks;
  float Trk_px[1000];
  float Trk_py[1000];
  float Trk_pz[1000];
  int Trk_charge[1000];
  float Trk_chi2[1000];
  float Trk_ndf[1000]; 
  float Trk_proj_ecal_x[1000];
  float Trk_proj_ecal_y[1000];
  float Trk_proj_ecal_z[1000];
  float Trk_proj_hcal_x[1000];
  float Trk_proj_hcal_y[1000];
  float Trk_proj_hcal_z[1000];

  int mcpart_num;
  int mcpart_index[1000];
  int mcpart_geid[1000];
  int mcpart_idVtx[1000];
  float mcpart_px[1000];
  float mcpart_py[1000];
  float mcpart_pz[1000];
  float mcpart_E[1000];
  int mcpart_charge[1000];
  float mcpart_Vtx_x[1000];
  float mcpart_Vtx_y[1000];
  float mcpart_Vtx_z[1000];

 protected:

 public:

  StSimpleReaderMaker(StMuDstMaker* maker) ;       //  Constructor
  virtual          ~StSimpleReaderMaker( ) ;       //  Destructor

  Int_t Init    ( ) ;                       //  Initiliaze the analysis tools ... done once
  Int_t Make    ( ) ;                       //  The main analysis that is done on each event
  Int_t Finish  ( ) ;                       //  Finish the analysis, close files, and clean up.

  void SetOutputFileName(TString name) {mOutputFileName = name;} // Make name available to member functions
  
  ClassDef(StSimpleReaderMaker,1)                  //  Macro for CINT compatability
    
};

#endif


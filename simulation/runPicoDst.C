#include "StFwdTrackMaker/macro/pico/StPicoFwdTrack.hpp"
#include "StFwdTrackMaker/macro/pico/StPicoFwdVertex.hpp"
#include "StFwdTrackMaker/macro/pico/StPicoFcsHit.hpp"
#include "StFwdTrackMaker/macro/pico/StPicoFcsCluster.hpp"
// #include "StRoot/StPicoEvent/StPicoEvent.h"

TClonesArray *fwdTracks   = new TClonesArray("StPicoFwdTrack", 1000);
TClonesArray *fwdVertices = new TClonesArray("StPicoFwdVertex", 1000);
TClonesArray *fcsHits     = new TClonesArray("StPicoFcsHit", 1000);
TClonesArray *fcsClusters = new TClonesArray("StPicoFcsCluster", 1000);
// TClonesArray *picoEvent   = new TClonesArray("StPicoEvent", 1);

void runPicoBfc() 
    {
        TFile *fOutput = new TFile("pico_output.root", "RECREATE");
        TH1F *h1_num_of_tracks = new TH1F("h1_num_of_tracks", "Number of Tracks per Event", 100, 0, 100);
        h1_num_of_tracks->SetXTitle("Number of Primary Tracks/Event");
        h1_num_of_tracks->SetYTitle("Counts");
        TH1F* h1_track_charge = new TH1F("h1_track_charge", "Track Charge Distribution", 5, -2.5, 2.5);
        h1_track_charge->SetXTitle("Charge [e]");
        h1_track_charge->SetYTitle("Counts");
        TH1F* h1_track_pt = new TH1F("h1_track_pt", "Track Transverse Momentum", 100, 0, 10);
        h1_track_pt->SetXTitle("p_{T} [GeV/c]");
        h1_track_pt->SetYTitle("Counts");
        TH1F* h1_num_of_fit_pts = new TH1F("h1_num_of_fit_pts", "Fit Points per Track", 20, -0.5, 19.5);
        h1_num_of_fit_pts->SetXTitle("Number of Fit Points");
        h1_num_of_fit_pts->SetYTitle("Counts");


        TChain *chain = new TChain("PicoDst");
        // chain->Add("/gpfs/mnt/gpfs01/star/pwg_tasks/FwdCalib/PROD/forwardCrossSection_2022/27082025/st_physics_23062011_raw_7500010.picoDst.root");
        // chain->Add("/gpfs/mnt/gpfs01/star/pwg_tasks/FwdCalib/PROD/forwardCrossSection_2022/27082025/st_physics_23062011_raw_7500010.picoDst.root");
        chain->Add("/gpfs/mnt/gpfs01/star/pwg_tasks/FwdCalib/PROD/forwardCrossSection_2022/27082025/st_physics_23062010_raw_3500008.picoDst.root");
        chain->SetBranchAddress("FwdTracks", &fwdTracks);
        chain->SetBranchAddress("FwdVertices", &fwdVertices);
        chain->SetBranchAddress("FcsHits", &fcsHits);
        chain->SetBranchAddress("FcsClusters", &fcsClusters);
        // chain->SetBranchAddress("Event", &picoEvent);

        size_t nEntries = chain->GetEntries();
        cout << "Number of events: " << nEntries << endl;
        // Fortesting, only process first 10 events
        if (nEntries > 10) nEntries = 1000;
        int nGlobalTracks = 0;
        for (size_t i = 0; i < nEntries; ++i) 
            {
                fwdTracks->Clear(); // Clear the TClonesArray for each entry
                fwdVertices->Clear(); // Clear the TClonesArray for each entry
                fcsHits->Clear(); // Clear the TClonesArray for each entry
                fcsClusters->Clear(); // Clear the TClonesArray for each entry

                chain->GetEntry(i);
                
                cout << "Event " << i << ": " 
                     << fwdTracks->GetEntriesFast() << " FwdTracks, "
                     << fwdVertices->GetEntriesFast() << " FwdVertices, "
                     << fcsHits->GetEntriesFast() << " FcsHits, "
                     << fcsClusters->GetEntriesFast() << " FcsClusters"
                     << endl;

                h1_num_of_tracks->Fill(fwdTracks->GetEntriesFast());
                     
                for (int j = 0; j < fwdTracks->GetEntriesFast() && fwdTracks->GetEntriesFast() < 50; ++j) 
                    {
                        // cout << "Processing FwdTrack " << j << endl;
                        StPicoFwdTrack *fwdTrack = static_cast<StPicoFwdTrack*>(fwdTracks->At(j));
                        // cout << "  FwdTrack track index " << fwdTrack->vertexIndex() << endl;
                        cout << "  FwdTrack is global: " << (fwdTrack->isGlobalTrack() ? "true" : "false") << endl;
                        if (fwdTrack->isGlobalTrack() == true) 
                            {
                                cout << "  FwdTrack " << j << " is a global track, proceeding..." << endl;
                                nGlobalTracks++;
                                cout << "  FwdTrack " << j 
                                     << ": id=" << fwdTrack->id() 
                                     << ", charge=" << fwdTrack->charge() 
                                     << ", p=(" << fwdTrack->momentum().X() << ", " 
                                                  << fwdTrack->momentum().Y() << ", " 
                                                  << fwdTrack->momentum().Z() << ")"
                                     << ", chi2=" << fwdTrack->chi2()
                                     << ", nFitPoints=" << fwdTrack->numberOfFitPoints()
                                     << endl;
                                h1_track_charge->Fill(fwdTrack->charge());
                                h1_track_pt->Fill(fwdTrack->momentum().Perp());
                            }
                    }
                cout << "Total global tracks so far: " << nGlobalTracks << endl;
            }
        h1_num_of_tracks->Write();
        h1_track_charge->Write();
        h1_track_pt->Write();
        h1_num_of_fit_pts->Write();
        fOutput->Close();
        cout << "Output written to: " << fOutput->GetPath() << "/" << fOutput->GetName() << endl;
    }
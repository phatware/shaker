//
//  ContentView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import SwiftUI
import MapKit
import CoreLocation
import CoreBluetooth

///////////////////////////////////////////////////////////////////////////////////////////
/// Content view
///

struct ContentView: View
{
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var modelData: ShakerModel
    
    var body: some View {
        TabView {
            CoctailsView()
                .tabItem {
                    Label("Coctails", systemImage: "wineglass")
                    Text("Coctails")
                }
            IngredientsView()
                .tabItem {
                    Label("Ingredients", systemImage: "checklist")
                    Text("Ingredients")
                }
            PlayView()
                .tabItem {
                    Label("Play!", systemImage: "gamecontroller")
                    Text("Play!")
                }
            MapContentView()
                .tabItem {
                    Label("Map", systemImage: "map")
                    Text("Map")
                }
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                    Text("Account")
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                LocationService.shared.requestLocation()
            } else if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .background {
                print("Background")
            }
        }
        .navigationTitle("Shaker")
        .onAppear() {
            modelData.central.startCentral(modelData)
        }
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View {
        ContentView()
            .environmentObject(ShakerModel())
    }
}


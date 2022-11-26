//
//  ContentView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import SwiftUI
import MapKit
import CoreLocation

enum SearchScope: String, CaseIterable {
    case alcoholic, alcoholfree
}

struct CoctailRow: View {
    
    var rec_id: Int64
    let database: CoctailsDatabase

    private var name : String {
        return database.getRecipeName(rec_id, alcohol: true)?["name"] as? String ?? "(Unknown)"
    }
    
    var body: some View {
        NavigationLink(destination: Text(name)) {
            Text(name)
                .searchCompletion(name)
                .foregroundColor(.black)
        }
    }
}

struct CoctailsView: View {
    
    let database : CoctailsDatabase

    @State private var searchText = ""
    @State private var column = "name"
    
    private var filter: String {
        return "\(column) LIKE '%\(searchText)%'"
    }
    
    private var alcoholic: [NSNumber] {
        if searchText.isEmpty {
            return database.getUnlockedRecordList(true, filter: nil, addName: false) as? [NSNumber] ?? []
        }
        else {
            return database.getUnlockedRecordList(true, filter: self.filter, addName: false) as? [NSNumber] ?? []
        }
    }
    private var non_alcoholic: [NSNumber] {
        if searchText.isEmpty {
            return database.getUnlockedRecordList(false, filter: nil, addName: false) as? [NSNumber] ?? []
        }
        else {
            return database.getUnlockedRecordList(false, filter: self.filter, addName: false) as? [NSNumber] ?? []
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(alcoholic, id: \.self) { rec_id in
                        CoctailRow(rec_id: rec_id.int64Value, database: database)
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer) {
                    //                ForEach(SearchScope.allCases, id: \.self) { scope in
                    //                    Text(scope.rawValue.capitalized)
                    //                }
                }
                // .listStyle(.inset)
            }
            .navigationTitle("Coctails")
        }
    }
}

struct PlayView: View {
    var body: some View {
        Text("Play!")
    }
}

struct AccountView: View {
    var body: some View {
        Text("Account")
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    
    var database : CoctailsDatabase {
        let db = CoctailsDatabase()
        _ = db.initializeDatabase()
        return db
    }

    var body: some View {
        TabView {
            CoctailsView(database: database)
                .tabItem {
                    Label("Coctails", systemImage: "wineglass")
                    Text("Coctails")
                }
            CategoriesView(database: database)
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

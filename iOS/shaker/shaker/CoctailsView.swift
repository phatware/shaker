//
//  CoctailsView.swift
//  shaker
//
//  Created by Stan Miasnikov on 12/9/22.
//

import SwiftUI

///////////////////////////////////////////////////////////////////////////////////////////
/// Search Scope

enum SearchScope: String, CaseIterable
{
    case alcoholic, alcoholfree
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Coctail Details, Identifiable

struct CoctailDetails: Identifiable
{
    let id = UUID()
    let name: String
    let category: String
    let rec_id: Int64
    let rating: Int
    let enabled: Bool
    let glass: String
    let shopping: String
    // extended optional fileds
    let ingredients: String?
    let instructions: String?
    let user_rec_id: Int64
    let user_rating: String?
    let note: String?
    let photo: Image?
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Coctail Row View

struct CoctailRow: View
{
    @EnvironmentObject var modelData: ShakerModel
    var rec_id: Int64
    
    private var coctail : CoctailDetails {
        
        let info  = modelData.database.getRecipeName(rec_id, alcohol: true) as? [String:Any]
        let c = CoctailDetails(name: info?["name"] as? String ?? "(Unknown)",
                               category: info?["category"] as? String ?? "",
                               rec_id: rec_id,
                               rating: info?["rating"] as? Int ?? 0,
                               enabled: info?["enabled"] as? Bool ?? false,
                               glass: info?["glass"] as? String ?? "",
                               shopping: info?["shopping"] as? String ?? "",
                               ingredients: nil,
                               instructions: nil,
                               user_rec_id: -1,
                               user_rating: nil,
                               note: nil,
                               photo: nil)
        return c
    }
    
    var body: some View {
        NavigationLink {
            CoctailDetailsView(rec_id: rec_id, alcogol: true)

        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(coctail.name)
                        .foregroundColor(.black)
                        .font(.title3)
                    Text("\(coctail.category) served in a \(coctail.glass)")
                        .foregroundColor(.black)
                        .font(.footnote)
                }
                .searchCompletion(coctail.name)
                Spacer()
                if coctail.rating == 0 {
                    Text("0☆")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                else {
                    Text(String(format:"%.1f⭐️", coctail.rating))
                        .font(.title2)
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Coctails View

struct CoctailsView: View
{
    @EnvironmentObject var modelData: ShakerModel
    
    @State private var searchText = ""
    @State private var column = "name"
    
    private var filter: String {
        return "\(column) LIKE '%\(searchText.sqlString)%'"
    }
    
    private var alcoholic: [Int64] {
        if searchText.isEmpty {
            return modelData.database.getUnlockedRecordList(true, filter: nil, addName: false) as? [Int64] ?? []
        }
        else {
            return modelData.database.getUnlockedRecordList(true, filter: self.filter, addName: false) as? [Int64] ?? []
        }
    }
    private var non_alcoholic: [Int64] {
        if searchText.isEmpty {
            return modelData.database.getUnlockedRecordList(false, filter: nil, addName: false) as? [Int64] ?? []
        }
        else {
            return modelData.database.getUnlockedRecordList(false, filter: self.filter, addName: false) as? [Int64] ?? []
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(alcoholic, id: \.self) { rec_id in
                        CoctailRow(rec_id: rec_id)
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer) {
                    //                ForEach(SearchScope.allCases, id: \.self) { scope in
                    //                    Text(scope.rawValue.capitalized)
                    //                }
                }
                .listStyle(InsetListStyle())
            }
            .navigationTitle("Coctails")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        print("button pressed")
                        
                    }) {
                        Image(systemName: "gear")
                            // .renderingMode(Image.TemplateRenderingMode?.init(Image.TemplateRenderingMode.original))
                    }
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Coctails View Preview

struct CoctailsView_Previews: PreviewProvider {
    static var previews: some View {
        CoctailsView()
            .environmentObject(ShakerModel())
    }
}

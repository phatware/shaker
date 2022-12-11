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
    @State private var searchin = SearchSelector.name
    @State private var sortby = SortSelector.name
    @State private var order = OrderSelector.decending
    @State private var groupby = GroupSelector.none
    @State private var showna = false

    enum SortSelector: String, CaseIterable, Identifiable {
        case name = "Title"
        case rating = "Rating"
        case update = "Update Date"
        
        var id: SortSelector { self }
    }

    enum GroupSelector: String, CaseIterable, Identifiable {
        case none = "None"
        case category = "Category"
        case glass = "Glass Type"
        
        var id: GroupSelector { self }
    }

    enum OrderSelector: String, CaseIterable, Identifiable {
        case ascending = "Ascending Order"
        case decending = "Decending Order"
        
        var id: OrderSelector { self }
    }

    enum SearchSelector: String, CaseIterable, Identifiable {
        case name = "Titles"
        case instructions = "Instructions"
        case ingredients = "Ingredients"
        
        var id: SearchSelector { self }
    }

    private var filter: String {
        let column : String
        switch(searchin) {
        case .name:
            column = "name"
            
        case .instructions:
            column = "instructions"
            
        case .ingredients:
            column = "ingredients"
        }
        return "\(column) LIKE '%\(searchText.sqlString)%'"
    }
    
    private var sort: String {
        let column1: String
        let column2: String
        switch(sortby) {
        case .name:
            column2 = "name"
        case .rating:
            column2 = "rating"
        case .update:
            column2 = "modified"
        }
        switch(groupby) {
        case .none:
            column1 = ""
        case .category:
            column1 = "category_id"
        case .glass:
            column1 = "glass_id"
        }
        // note: here the order is opposite because the order represents "switch to order..." menu
        let o = order == OrderSelector.ascending ? "DESC" : "ASC"
        if column1 != "" {
            return "\(column1) ASC, \(column2) \(o)"
        }
        return "\(column2) \(o)"
    }
    
    private var alcoholic: [Int64] {
        if searchText.isEmpty {
            return modelData.database.getUnlockedRecordList(true, filter: nil, sort: self.sort, addName: false) as? [Int64] ?? []
        }
        else {
            return modelData.database.getUnlockedRecordList(true, filter: self.filter, sort: self.sort, addName: false) as? [Int64] ?? []
        }
    }
    private var non_alcoholic: [Int64] {
        if searchText.isEmpty {
            return modelData.database.getUnlockedRecordList(false, filter: nil, sort: self.sort, addName: false) as? [Int64] ?? []
        }
        else {
            return modelData.database.getUnlockedRecordList(false, filter: self.filter, sort: self.sort, addName: false) as? [Int64] ?? []
        }
    }
        
    var body: some View {
        NavigationView {
            VStack {
                List {
                    // TODO: finish group by...
                    if showna {
                        CollapsibleSection(title: "Alcoholic Beverages", isExpanded: true) {
                            ForEach(alcoholic, id: \.self) { rec_id in
                                RecipeRow(rec_id: rec_id)
                            }
                        }
                        CollapsibleSection(title: "Alcohol-free Beverages", isExpanded: true) {
                            ForEach(non_alcoholic, id: \.self) { rec_id in
                                RecipeRow(rec_id: rec_id)
                            }
                        }
                    }
                    else {
                        ForEach(alcoholic, id: \.self) { rec_id in
                            CoctailRow(rec_id: rec_id)
                        }
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
                ToolbarItem {
                    Menu {
                        Menu {
                            Picker("Sort By", selection: $sortby) {
                                ForEach(SortSelector.allCases) { ss in
                                    Text(ss.rawValue).tag(ss)
                                }
                            }
                            Button {
                                order = order == OrderSelector.ascending ? OrderSelector.decending : OrderSelector.ascending
                            } label: {
                                let imagename = order == OrderSelector.ascending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill"
                                Label(order.rawValue, systemImage: imagename)
                            }
                        } label: {
                            Label("Sory by", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        Menu {
                            Picker("Group By", selection: $groupby) {
                                ForEach(GroupSelector.allCases) { gs in
                                    Text(gs.rawValue).tag(gs)
                                }
                            }
                        } label: {
                            Label("Group by", systemImage: "rectangle.3.group")
                        }
                        Menu {
                            Picker("Search in", selection: $searchin) {
                                ForEach(SearchSelector.allCases) { gs in
                                    Text(gs.rawValue).tag(gs)
                                }
                            }
                        } label: {
                            Label("Search in", systemImage: "magnifyingglass")
                        }
                        Toggle(isOn: $showna) {
                            Label("Alcohol-free Recipes", systemImage: "drop.degreesign.slash")
                        }
                    } label: {
                        Label("View Settings", systemImage: "slider.horizontal.3")
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

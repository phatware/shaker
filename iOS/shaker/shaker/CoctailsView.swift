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
/// Coctail Row View

struct CoctailRow: View
{
    @EnvironmentObject var modelData: ShakerModel
    var rec_id: Int64
    let alcohol: Bool
    
    private var coctail : CoctailDetails {
        return modelData.recipeDetails(rec_id, alcohol: alcohol, includeImage: false)
    }
    
    var body: some View {
        NavigationLink(destination: CoctailDetailsView(rec_id: rec_id, alcogol: alcohol))
        {
            let c = self.coctail
            HStack {
                VStack(alignment: .leading) {
                    Text(c.name)
                        .foregroundColor(.black)
                        .font(.title3)
                    Text("\(c.category) served in a \(c.glass)")
                        .foregroundColor(.black)
                        .font(.footnote)
                }
                Spacer()
                if c.rating == 0 {
                    Text("0☆")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                else {
                    Text(String(format:"%.1f⭐️", c.rating))
                        .font(.title2)
                }
            }
            .searchCompletion(c.name)
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

    private var filter: String? {
        if searchText.isEmpty {
            return nil
        }
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
        let col: String
        switch(sortby) {
        case .name:
            col = "name"
        case .rating:
            col = "rating"
        case .update:
            col = "modified"
        }
        let o = order == OrderSelector.ascending ? "DESC" : "ASC"
        return "\(col) \(o)"
    }
    
    private var alcoholic: [Int64:[Int64]] {
        var group: String? = nil
        switch(groupby) {
        case .none:
            group = nil
        case .category:
            group = "category_id"
        case .glass:
            group = "glass_id"
        }
        return modelData.recipeList(true, sort: "name ASC", filter: self.filter, group: group)
    }
    private var non_alcoholic: [Int64:[Int64]] {
        var group: String? = nil
        switch(groupby) {
        case .none:
            group = nil
        case .category:
            group = "category_id"
        case .glass:
            group = "glass_id"
        }
        return modelData.recipeList(false, sort: "name ASC", filter: self.filter, group: group)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    let drinks = alcoholic
                    switch(self.groupby) {
                    case .none:
                        if showna {
                            CollapsibleSection(title: "Alcoholic Beverages", setExpanded: true) {
                                ForEach(drinks[-1]!, id: \.self) { rec_id in
                                    RecipeRow(rec_id: rec_id, alcohol: true)
                                }
                            }
                            CollapsibleSection(title: "Alcohol-free Beverages", setExpanded: true) {
                                ForEach(non_alcoholic[-1]!, id: \.self) { rec_id in
                                    RecipeRow(rec_id: rec_id, alcohol: false)
                                }
                            }
                        }
                        else {
                            if drinks.count > 0 {
                                ForEach(drinks[-1]!, id: \.self) { rec_id in
                                    CoctailRow(rec_id: rec_id, alcohol: true)
                                }
                            }
                        }
                        
                    case .category:
                        let keys = drinks.keys.sorted()
                        ForEach(keys, id: \.self) { key in
                            let cat = modelData.database.categoryName(key)
                            CollapsibleSection(title: cat, setExpanded: true) {
                                ForEach(drinks[key]!, id: \.self) { rec_id in
                                    RecipeRow(rec_id: rec_id, alcohol: true)
                                }
                            }
                        }
                        
                    case .glass:
                        let keys = drinks.keys.sorted()
                        ForEach(keys, id: \.self) { key in
                            let glass = modelData.database.glassName(key)
                            CollapsibleSection(title: glass, setExpanded: true) {
                                ForEach(drinks[key]!, id: \.self) { rec_id in
                                    RecipeRow(rec_id: rec_id, alcohol: true)
                                }
                            }
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
                            if self.groupby != .none {
                                Button {
                                    NotificationCenter.default.post(name: .expandCollapse, object: true)
                                } label: {
                                    Label("Expand All", systemImage: "rectangle.expand.vertical")
                                }
                                Button {
                                    NotificationCenter.default.post(name: .expandCollapse, object: false)
                                } label: {
                                    Label("Collapse All", systemImage: "rectangle.compress.vertical")
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

extension Notification.Name {
    static let expandCollapse = Notification.Name("expand_collapse_coctail_list")
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Coctails View Preview

struct CoctailsView_Previews: PreviewProvider {
    static var previews: some View {
        CoctailsView()
            .environmentObject(ShakerModel())
    }
}

//
//  IngredientsView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/24/22.
//

import SwiftUI

///////////////////////////////////////////////////////////////////////////////////////////
/// Recipe Row View

struct RecipeRow: View
{
    @EnvironmentObject var modelData: ShakerModel
    var rec_id: Int64
    var alcohol: Bool
    
    private var name : String {
        let info = modelData.recipeInfo(rec_id, alcohol: alcohol)
        return info.name
    }
    
    var body: some View {
        NavigationLink(destination: CoctailDetailsView(rec_id: rec_id, alcogol: alcohol)) {
            Text(name)
        }
    }
}

struct CoctailSectionHeader: View
{
    var title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .foregroundColor(.black)
                .padding()
            Spacer()
            //            Image(systemName: "chevron.up")
            //                .rotationEffect(.degrees(isExpanded ? 180 : 0))
            //                .foregroundColor(.black)
            //                .padding(.trailing, 10)
        }
        .background(Color(white: 0.95))
        .listRowInsets(EdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 0))
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Filtered Recipes View

struct FilteredRecipesView: View
{
    @EnvironmentObject var modelData: ShakerModel
    let ingredient : String
    let alcohol: Bool
    
    private var filter: String {
        return "ingredients LIKE '%\(ingredient.sqlString)%'"
    }
    
    private var alcoholic: [Int64] {
        let res = modelData.recipeList(true, sort: "name ASC", filter: self.filter)
        if res.count > 0 {
            return res[-1] ?? []
        }
        return []
    }
    private var non_alcoholic: [Int64] {
        let res = modelData.recipeList(false, sort: "name ASC", filter: self.filter)
        if res.count > 0 {
            return res[-1] ?? []
        }
        return []
    }
    
    var body: some View {
        VStack {
            List {
                let alco = alcoholic
                let free = non_alcoholic
                if alco.count > 0 {
                    Section {
                        ForEach(alco, id: \.self) { rec_id in
                            RecipeRow(rec_id: rec_id, alcohol: alcohol)
                        }
                    } header: {
                        CoctailSectionHeader(title: "Alcoholic Beverages")
                    }
                }
                if free.count > 0 {
                    Section {
                        ForEach(free, id: \.self) { rec_id in
                            RecipeRow(rec_id: rec_id, alcohol: alcohol)
                        }
                    } header: {
                        CoctailSectionHeader(title: "Non-alcoholic Beverages")
                    }
                }
            }
            .listStyle(InsetListStyle())
        }
        .navigationTitle(ingredient)
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Ingredient Row view

struct IngredientRow: View
{
    @EnvironmentObject var modelData: ShakerModel
    var ing: Ingredient
    let alcohol: Bool
    
    var body: some View {
        var ebabled = ing.enabled
        
        let entoggle = Binding<Bool>(get: { ebabled },
                                     set: {on in
            
            if modelData.database.enableIngredient(on, withRecordid: ing.rec_id) {
                ebabled = on
            }
        } )
        
        NavigationLink(destination: FilteredRecipesView(ingredient: ing.name, alcohol: alcohol)) {
            VStack(alignment: .leading) {
                Toggle(isOn: entoggle){
                    Text(ing.name)
                        .font(.body)
                }
                .toggleStyle(.automatic)
                // Spacer()
                Text("Used in \(ing.used) recipes")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, -6)
            }
            .searchCompletion(ing.name)
        }
        .listRowSeparator(.visible)
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Ingredients View

struct IngredientsView: View
{
    @EnvironmentObject var modelData: ShakerModel
    @State private var expandAll = false
    @State private var order = OrderSelector.decending
    @State private var searchText = ""
    @State private var showall = true
    @State private var alcohol = true
    
    enum OrderSelector: String, CaseIterable, Identifiable {
        case ascending = "Ascending Order"
        case decending = "Decending Order"
        
        var id: OrderSelector { self }
    }
    
    private var filter: String? {
        if self.searchText.isEmpty {
            return nil
        }
        return "item LIKE '%\(searchText.sqlString)%'"
    }

    private var sort: String {
        let o = order == OrderSelector.ascending ? "DESC" : "ASC"
        return "item \(o)"
    }

    private var categories: [IngredientCategory] {
        
        return modelData.ingredients(showall: self.showall, sort: self.sort, filter: self.filter)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(categories, id: \.self) { category in
                        CollapsibleSection(title: category.name, setExpanded: true) {
                            ForEach(category.ingredients, id: \.self) { ing in
                                IngredientRow(ing: ing, alcohol: alcohol)
                            }
                        }
                    }
                }
                // .listStyle(InsetGroupedListStyle())
                .searchable(text: $searchText, placement: .navigationBarDrawer) {
                    //                ForEach(SearchScope.allCases, id: \.self) { scope in
                    //                    Text(scope.rawValue.capitalized)
                    //                }
                }
                .listStyle(InsetListStyle())
            }
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button {
                            order = order == OrderSelector.ascending ? OrderSelector.decending : OrderSelector.ascending
                        } label: {
                            let imagename = order == OrderSelector.ascending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill"
                            Label(order.rawValue, systemImage: imagename)
                        }
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
                        Toggle(isOn: $showall) {
                            Label("Show Disabled Igredients", systemImage: "eye.slash")
                        }
                    } label: {
                        Label("View Settings", systemImage: "slider.horizontal.3")
                    }
                }
            }
        }
    }
}

extension String
{
    public var sqlString : String {
        return self.replacingOccurrences(of: "\'", with: "\'\'")
    }
}


struct IngredientsView_Previews: PreviewProvider
{
    static var previews: some View {
        IngredientsView()
            .environmentObject(ShakerModel())
    }
}

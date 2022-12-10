//
//  IngredientsView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/24/22.
//

import SwiftUI

///////////////////////////////////////////////////////////////////////////////////////////
/// Ingredient, Identifiable, Hashable
///
struct Ingredient: Identifiable, Hashable
{
    let id = UUID()
    let name: String
    let rec_id: Int64
    let used: Int
    var enabled: Bool
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Ingredient Category, Identifiable, Hashable

struct IngredientCategory : Identifiable, Hashable
{
    let id = UUID()
    // var index: Index?
    let name: String
    let rec_id: Int64
    var ingredients : [Ingredient] = []
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Recipe Row View

struct RecipeRow: View {
    @EnvironmentObject var modelData: ShakerModel
    var rec_id: Int64
    
    private var name : String {
        return modelData.recipeName(rec_id)
    }
    
    var body: some View {
        NavigationLink(destination: Text(name)) {
            Text(name)
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Filtered Recipes View

struct FilteredRecipesView: View
{
    @EnvironmentObject var modelData: ShakerModel
    let ingredient : String
    
    private var filter: String {
        return "ingredients LIKE '%\(ingredient)%'"
    }
    
    private var alcoholic: [Int64] {
        return modelData.database.getUnlockedRecordList(true, filter: self.filter, addName: false) as? [Int64] ?? []
    }
    private var non_alcoholic: [Int64] {
        return modelData.database.getUnlockedRecordList(false, filter: self.filter, addName: false) as? [Int64] ?? []
    }
    
    var body: some View {
        VStack {
            List {
                if alcoholic.count > 0 {
                    Section {
                        ForEach(alcoholic, id: \.self) { rec_id in
                            RecipeRow(rec_id: rec_id)
                        }
                    } header: {
                        Text("Alcoholic Beverages")
                    }
                }
                if non_alcoholic.count > 0 {
                    Section {
                        ForEach(non_alcoholic, id: \.self) { rec_id in
                            RecipeRow(rec_id: rec_id)
                        }
                    } header: {
                        Text("Non-alcoholic Beverages")
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
    
    var body: some View {
        var ebabled = ing.enabled
        
        let entoggle = Binding<Bool>(get: { ebabled },
                                     set: {on in
            
            if modelData.database.enableIngredient(on, withRecordid: ing.rec_id) {
                ebabled = on
            }
        } )
        
        NavigationLink(destination: FilteredRecipesView(ingredient: ing.name)) {
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
        }
        .listRowSeparator(.visible)
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// Ingredients View

struct IngredientsView: View
{
    @EnvironmentObject var modelData: ShakerModel
    
    private var categories: [IngredientCategory] {
        let data = modelData.database.inredientsCategories() as? [NSDictionary] ?? []
        var result: [IngredientCategory] = []
        for category in data {
            var ic = IngredientCategory(name: category["category"] as? String ?? "",
                                        rec_id: category["id"] as? Int64 ?? 0)
            
            if let subitems = modelData.database.inredients(forCategory: ic.rec_id,
                                                            showall: true,
                                                            filter: nil,
                                                            sort: nil) as? [NSDictionary] {
                for sitem in subitems {
                    let i = Ingredient(name: sitem["name"] as? String ?? "",
                                       rec_id: sitem["id"] as? Int64 ?? 0,
                                       used: sitem["used"] as? Int ?? 0,
                                       enabled: sitem["enabled"] as? Bool ?? false)
                    ic.ingredients.append(i)
                }
            }
            result.append(ic)
        }
        return result
    }
    
    var body: some View {
        VStack {
            NavigationView {
                List {
                    ForEach(categories, id: \.self) { category in
                        
                        CollapsibleSection(title: category.name) {
                            
                            ForEach(category.ingredients, id: \.self) { ing in
                                IngredientRow(ing: ing)
                            }
                        }
                    }
                }
                // .listStyle(InsetGroupedListStyle())
                .navigationTitle("Ingredients")
                .listStyle(InsetListStyle())
            }
        }
    }
}


struct IngredientsView_Previews: PreviewProvider
{
    static var previews: some View {
        IngredientsView()
            .environmentObject(ShakerModel())
    }
}

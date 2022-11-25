//
//  IngredientsView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/24/22.
//

import SwiftUI

struct IngredientRow: View {
    
    var ing: NSDictionary
    let database: CoctailsDatabase
    
    var name: String {
        return ing["name"] as? String ?? ""
    }
    var used: Int {
        return ing["used"] as? Int ?? 0
    }

    var body: some View {
        var ebabled = (self.ing["enabled"] as? Int != 0)
        
        let entoggle = Binding<Bool>(get: { ebabled },
                                     set: {on in
            let rid = ing["id"] as? Int64 ?? -1
            
            if database.enableIngredient(on, withRecordid: rid) {
                ebabled = on
            }
        } )
        
        VStack(alignment: .leading) {
            Toggle(isOn: entoggle){
                Text(name)
                    .font(.body)
            }
            .toggleStyle(.automatic)
            // Spacer()
            Text("Used in \(used) recipes")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, -6)
        }
        // .padding()
    }
}

struct IngredientsView: View {
    
    let category_id: Int64
    let database: CoctailsDatabase
    let category: String
    
    @State private var searchText = ""
    
    var ingredients: [NSDictionary] {
        if searchText.isEmpty {
            return database.inredients(forCategory: category_id, showall: true, filter: nil, sort: nil) as? [NSDictionary] ?? []
        }
        else {
            let filter = "item LIKE '%\(searchText)%'"
            return database.inredients(forCategory: category_id, showall: true, filter: filter, sort: nil) as? [NSDictionary] ?? []
        }
    }
    
    var body: some View {
        List {
            ForEach(ingredients, id: \.self) { ing in
                IngredientRow(ing: ing, database: database)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer) {
            ForEach(SearchScope.allCases, id: \.self) { scope in
                Text(scope.rawValue.capitalized)
            }
        }            // .navigationTitle("Coctails")
        .navigationTitle(category)
        .navigationBarItems(trailing: Button(action: {
            print("Edit button pressed...")
        }) {
            Image(systemName: "slider.horizontal.2.square.on.square") // "slider.horizontal.3")
        })
    }
}

struct CategoryRow: View {
    
    var category: NSDictionary
    let database: CoctailsDatabase
    
    var name: String {
        return category["category"] as? String ?? ""
    }
    var cid: Int64 {
        return category["id"] as? Int64 ?? 0
    }
    
    var body: some View {
        NavigationLink(destination: IngredientsView(category_id: cid, database: database, category: name)) {
            Text(name)
        }
    }
}


struct CategoriesView: View {
    
    let database : CoctailsDatabase
    
    var categories: [NSDictionary] {
        return database.inredientsCategories() as? [NSDictionary] ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(categories, id: \.self) { category in
                        CategoryRow(category: category, database: database)
                    }
                }
            }
            .navigationTitle("Ingredients")
            // .navigationTitle("Ingredients")
            //            .searchable(text: $searchText, placement: .navigationBarDrawer) {
            //                ForEach(SearchScope.allCases, id: \.self) { scope in
            //                    Text(scope.rawValue.capitalized)
            //                }
            //            }            // .navigationTitle("Coctails")
        }
    }
}

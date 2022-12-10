//
//  ShakerModel.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/29/22.
//

import Foundation

final class ShakerModel: ObservableObject
{
    @Published var database: CoctailsDatabase = load()
    @Published var deviceid: String = makeid()
 
    func recipeName(_ rec_id: Int64, alcohol: Bool = true) -> String
    {
        return database.getRecipeName(rec_id, alcohol: alcohol)?["name"] as? String ?? "(Unknown)"
    }
    
}

func makeid() -> String
{
    let defaults = UserDefaults.standard
    guard let did = defaults.string(forKey: "device_id") else {
        let newid = UUID().uuidString
        defaults.set(newid, forKey: "device_id")
        return newid
    }
    return did
}

func load() -> CoctailsDatabase
{
    let db = CoctailsDatabase()
    _ = db.initializeDatabase()
    return db
}

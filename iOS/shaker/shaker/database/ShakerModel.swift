//
//  ShakerModel.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/29/22.
//

import Foundation
import CoreBluetooth
import SwiftUI

///////////////////////////////////////////////////////////////////////////////////////////
/// BT Info

struct BTDeviceInfo {
    
    enum BTDeviceState {
        case detected, ignored, configured
    }
    
    var state: BTDeviceState = .detected;
    
    var peer: BKRemotePeer
    var deviceid: UUID
    var nickname: String?
    var updated: TimeInterval = 0.0
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
/// Shaker Model

final class ShakerModel: ObservableObject
{
    @Published var database: CoctailsDatabase = load()
    @Published var deviceid: String = makeid()
    @Published var detectedDevices: [BTDeviceInfo] = []
    @Published var nickname: String = "<Unknown>"
    @Published var central = CentralDelegate()
    @Published var peripheral = PeripheralDelegatge()
    
    public static let REMOTEID_PREFIX: String = "C2DA0000"
    public static let REMOTE_TIMEOUT:  TimeInterval = 60
    
    init()
    {
        Task {
            try await Task.sleep(nanoseconds: UInt64(1.0 * Double(NSEC_PER_SEC)))
            central.startCentral(self)
            peripheral.startPeripheral(self)
        }
    }
    
    // database functions
    
    public func recipeDetails(_ rec_id: Int64, alcohol: Bool, includeImage: Bool) -> CoctailDetails
    {
        let info  = self.database.getRecipe(rec_id, alcohol: alcohol, noImage: !includeImage) as? [String:Any]
        
        let rating = info?["userrating"] as? Int ?? (info?["rating"] as? Int ?? 0)
        let star = "★"
        let star_part = "✩"
        var rstr = ""
        if rating < 1 {
            rstr = "Not rated yet"
        }
        else {
            for _ in 0..<rating {
                rstr += star
            }
            for _ in rating..<10 {
                rstr += star_part
            }
        }
        
        let c = CoctailDetails(name: info?["name"] as? String ?? "(Unknown)",
                               category: info?["category"] as? String ?? "",
                               rec_id: rec_id,
                               rating: rating,
                               enabled: info?["enabled"] as? Bool ?? false,
                               glass: info?["glass"] as? String ?? "",
                               shopping: info?["shopping"] as? String ?? "",
                               ingredients: info?["ingredients"] as? String ?? "",
                               instructions: info?["instructions"] as? String ?? "",
                               user_rec_id: info?["userrecord_id"] as? Int64 ?? 0,
                               user_rating: rstr,
                               note: info?["note"] as? String ?? "",
                               photo: info?["photo"] as? Image ?? nil)
        
        return c
    }
    
    public func recipeInfo(_ rec_id: Int64, alcohol: Bool) -> CoctailDetails
    {
        let info  = self.database.getRecipeName(rec_id, alcohol: alcohol) as? [String:Any]
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
    
    public func recipeList(_ alcohol: Bool, sort: String, filter: String? = nil, group: String? = nil) -> [Int64:[Int64]]
    {
        return self.database.getUnlockedRecordList(alcohol, filter: filter, sort: sort, group: group, range: NSMakeRange(0, 0)) as? [Int64:[Int64]] ?? [:]
    }
    
    public func ingredients(showall: Bool, sort: String, filter: String? = nil) -> [IngredientCategory]
    {
        let data = self.database.ingredientsCategories() as? [NSDictionary] ?? []
        var result: [IngredientCategory] = []
        for category in data {
            var ic = IngredientCategory(name: category["category"] as? String ?? "",
                                        rec_id: category["id"] as? Int64 ?? 0)
            
            if let subitems = self.database.inredients(forCategory: ic.rec_id,
                                                       showall: showall,
                                                       filter: filter,
                                                       sort: sort) as? [NSDictionary] {
                for sitem in subitems {
                    let i = Ingredient(name: sitem["name"] as? String ?? "",
                                       rec_id: sitem["id"] as? Int64 ?? 0,
                                       used: sitem["used"] as? Int ?? 0,
                                       enabled: sitem["enabled"] as? Bool ?? false)
                    ic.ingredients.append(i)
                }
            }
            if ic.ingredients.count > 0 {
                result.append(ic)
            }
        }
        return result
    }
        
    public func localName() -> String
    {
        let index: String.Index = self.deviceid.index(self.deviceid.startIndex, offsetBy: 8)
        let localName = String(self.deviceid[index...]).replacingOccurrences(of: "-", with: "")  // Unique device ID - make it 24 chars long
        return localName
    }
    
    // BT functions
    
    public func BTDeleteExpired()
    {
        let now = NSDate().timeIntervalSince1970
        for (index, device) in detectedDevices.enumerated() {
            if now - device.updated > ShakerModel.REMOTE_TIMEOUT {
                detectedDevices.remove(at: index)
            }
        }
    }
    
    public func BTDevice(_ forName: String) -> BTDeviceInfo?
    {
        for (_, device) in detectedDevices.enumerated() {
            if device.nickname == forName {
                return device
            }
        }
        return nil
    }
    
    public func BTDevice(_ forId: UUID) -> BTDeviceInfo?
    {
        for (_, device) in detectedDevices.enumerated() {
            if device.deviceid == forId {
                return device
            }
        }
        return nil
    }
    
    public func BTDevice(_ forRemote: BKRemotePeer) -> BTDeviceInfo?
    {
        for (_, device) in detectedDevices.enumerated() {
            if device.peer == forRemote {
                return device
            }
        }
        return nil
    }
    
    public func BTDevice(_ remote: BKRemotePeer, setState: BTDeviceInfo.BTDeviceState)
    {
        for index in 0..<detectedDevices.count {
            if detectedDevices[index].peer == remote {
                detectedDevices[index].state = setState
                detectedDevices[index].updated = NSDate().timeIntervalSince1970
                break
            }
        }
    }
    
    public func BTDevice(_ remote: BKRemotePeer, setName: String)
    {
        for index in 0..<detectedDevices.count {
            if detectedDevices[index].peer == remote {
                detectedDevices[index].nickname = setName
                detectedDevices[index].updated = NSDate().timeIntervalSince1970
                break
            }
        }
    }

    public func BTDeviceUpdate(_ remote: BKRemotePeer)
    {
        for index in 0..<detectedDevices.count {
            if detectedDevices[index].peer == remote {
                detectedDevices[index].updated = NSDate().timeIntervalSince1970
                break
            }
        }
    }

    public func BTDeviceNameToUuid(_ name: String) -> UUID?
    {
        let index1 = name.index(name.startIndex, offsetBy: 4)
        let index2 = name.index(name.startIndex, offsetBy: 8)
        let index3 = name.index(name.startIndex, offsetBy: 12)
        let uuidstr = "\(ShakerModel.REMOTEID_PREFIX)-\(name[..<index1])-\(name[index1..<index2])-\(name[index2..<index3])-\(name[index3...])"
        return UUID(uuidString: uuidstr)
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

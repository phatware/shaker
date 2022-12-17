//
//  ShakerModel.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/29/22.
//

import Foundation
import CoreBluetooth

struct BTDeviceInfo {
    var peer: BKRemotePeer?
    var devid: UUID?
    var name: String?
    var expires: TimeInterval = 0
    var connected: Bool = false
}


final class ShakerModel: ObservableObject
{
    @Published var database: CoctailsDatabase = load()
    @Published var deviceid: String = makeid()
    @Published var detectedDevices: [UUID:TimeInterval] = [:]
    @Published var connectedDevices: [BKRemotePeer] = []

    public static let REMOTE_TIMEOUT : TimeInterval = 60

    func recipeName(_ rec_id: Int64, alcohol: Bool = true) -> String
    {
        return database.getRecipeName(rec_id, alcohol: alcohol)?["name"] as? String ?? "(Unknown)"
    }
    
    public func deleteExpiredDevices()
    {
        let now = NSDate().timeIntervalSince1970
        var delkeys: [UUID] = []
        for device in detectedDevices {
            if now - device.value > ShakerModel.REMOTE_TIMEOUT {
                delkeys.append(device.key)
            }
        }
        for key in delkeys {
            detectedDevices.removeValue(forKey: key)
        }
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

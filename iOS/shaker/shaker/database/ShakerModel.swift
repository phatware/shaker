//
//  ShakerModel.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/29/22.
//

import Foundation
import CoreBluetooth

struct BTDeviceInfo {
    
    enum BTDeviceState {
        case disconnected, connecting, connected, ignored
    }
    
    var state: BTDeviceState = .disconnected;
    
    var peer: BKRemotePeer
    var deviceid: UUID
    var nickname: String?
    var updated: TimeInterval = 0.0
}


final class ShakerModel: ObservableObject
{
    @Published var database: CoctailsDatabase = load()
    @Published var deviceid: String = makeid()
    @Published var detectedDevices: [BTDeviceInfo] = []
    @Published var nickname: String = "<Unique_name>"
    
    public static let REMOTE_TIMEOUT : TimeInterval = 60
    
    public func recipeName(_ rec_id: Int64, alcohol: Bool = true) -> String
    {
        return database.getRecipeName(rec_id, alcohol: alcohol)?["name"] as? String ?? "<Unknown>"
    }
    
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
            detectedDevices[index].state = setState
            detectedDevices[index].updated = NSDate().timeIntervalSince1970
        }
    }
    
    public func BTDevice(_ remote: BKRemotePeer, setName: String)
    {
        for index in 0..<detectedDevices.count {
            detectedDevices[index].nickname = setName
            detectedDevices[index].updated = NSDate().timeIntervalSince1970
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

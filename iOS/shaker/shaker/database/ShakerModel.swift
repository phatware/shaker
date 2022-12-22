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
        case disconnected, connecting, connected, ignored, configured
    }
    
    var state: BTDeviceState = .disconnected;
    
    var peer: BKRemotePeer
    var deviceid: UUID
    var nickname: String?
    var updated: TimeInterval = 0.0
}

func onStateChange(_ model: ShakerModel, state: BKCentral.ContinuousScanState) -> Void
{
    // TODO: scanning state changed - stop/start peripheral? is this a good place?
    print("BLE scan state: \(state)")
    switch state {
    case .waiting:
        Task.detached(operation: {
            model.peripheral.startPeripheral(model)
        })
        break
    case .scanning:
        Task.detached(operation: {
            model.peripheral.stop()
        })
        break
    case .stopped:
        Task.detached(operation: {
            model.peripheral.stop()
        })
        break
    }
}

final class ShakerModel: ObservableObject
{
    @Published var database: CoctailsDatabase = load()
    @Published var deviceid: String = makeid()
    @Published var detectedDevices: [BTDeviceInfo] = []
    @Published var nickname: String = "<Unique_name>"
    @Published var central = CentralDelegate(onStateChange: onStateChange)
    @Published var peripheral = PeripheralDelegatge()
    
    public static let REMOTEID_PREFIX: String = "C2DA0000"
    public static let REMOTE_TIMEOUT:  TimeInterval = 60
    
    public func recipeName(_ rec_id: Int64, alcohol: Bool = true) -> String
    {
        return database.getRecipeName(rec_id, alcohol: alcohol)?["name"] as? String ?? "<Unknown>"
    }
    
    public func localName() -> String
    {
        let index: String.Index = self.deviceid.index(self.deviceid.startIndex, offsetBy: 8)
        let localName = String(self.deviceid[index...]).replacingOccurrences(of: "-", with: "")  // Unique device ID - make it 24 chars long
        return localName
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
            if detectedDevices[index].peer == remote {
                if (detectedDevices[index].state == .ignored || detectedDevices[index].state == .configured)
                    && (setState == .disconnected || setState == .connected) {
                    // do not set disconnected state if device is already in the configured or ignored state
                    continue
                }
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

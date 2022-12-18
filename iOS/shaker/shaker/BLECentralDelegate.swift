//
//  BLECentralDelegate.swift
//  shaker
//
//  Created by Stan Miasnikov on 12/13/22.
//

import Foundation
import CoreLocation
import CoreBluetooth

///////////////////////////////////////////////////////////////////////////////////////////
/// BLE Central Delegate (BKCentralDelegate, BKAvailabilityObserver)

class CentralDelegate : BKCentralDelegate, BKAvailabilityObserver
{
    private var modelData: ShakerModel?
    private var discoveries = [BKDiscovery]()
    private let central = BKCentral()
    
    deinit {
        _ = try? central.stop()
    }

    func startCentral(_ modelData: ShakerModel)
    {
        do {
            self.modelData = modelData
            central.delegate = self
            central.addAvailabilityObserver(self)
            let dataServiceUUID = UUID(uuidString: "C2436366-6B33-456E-9DA1-6394D9601C4C")!
            let dataServiceCharacteristicUUID = UUID(uuidString: "ECF0C0D1-FB70-43AA-B4D5-6B2B048D55CF")!
            let configuration = BKConfiguration(dataServiceUUID: dataServiceUUID, dataServiceCharacteristicUUID: dataServiceCharacteristicUUID)
            try central.startWithConfiguration(configuration)
        } catch let error {
            print("Error while starting: \(error)")
        }
    }
    
    internal func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause)
    {
        
    }
    
    // MARK: BKAvailabilityObserver
    
    internal func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability)
    {
        //availabilityView.availabilityObserver(availabilityObservable, availabilityDidChange: availability)
        if availability == .available {
            scan(central)
        } else {
            central.interruptScan()
            self.modelData?.BTDeleteExpired()
        }
    }
    
    // MARK: BKCentralDelegate
    
    internal func central(_ central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
    {
        print("Remote peripheral did disconnect: \(remotePeripheral)")
        if var device = self.modelData?.BTDevice(remotePeripheral) {
            device.updated = NSDate().timeIntervalSince1970
            device.connected = false
        }
    }
    
    private func scan(_ central: BKCentral)
    {
        central.scanContinuouslyWithChangeHandler({ changes, discoveries in
            for insertedDiscovery in changes.filter({ $0 == .insert(discovery: nil) }) {
                var connect = true
                for removedDiscovery in changes.filter({ $0 == .remove(discovery: nil) }) {
                    if removedDiscovery.discovery.remotePeripheral == insertedDiscovery.discovery.remotePeripheral {
                        connect = false
                        break
                    }
                }
                if connect {
                    if let name = insertedDiscovery.discovery.localName, let uuid = UUID(uuidString: name) {
                        if var device = self.modelData?.BTDevice(uuid) {
                            // already discovered, update time
                            device.updated = NSDate().timeIntervalSince1970
                            continue
                        }
                        // add new device to the list and connect to it to get config
                        let new_device = BTDeviceInfo(peer: insertedDiscovery.discovery.remotePeripheral, deviceid: uuid, updated: NSDate().timeIntervalSince1970)
                        self.modelData?.detectedDevices.append(new_device)
                        
                        print("Discovery: \(String(describing: insertedDiscovery.discovery.localName)) - connecting...")
                        self.connect(insertedDiscovery.discovery.remotePeripheral)
                    }
                }
            }
            
        }, stateHandler: { newState in
            if newState == .scanning {
                // TODO: scanning...
                return
            }
            else if newState == .stopped {
                self.discoveries.removeAll()
            }
        }, errorHandler: { error in
            print("Error from scanning: \(error)")
        })
    }
    
    public func connect(_ remotePeripheral : BKRemotePeripheral)
    {
        central.connect(remotePeripheral: remotePeripheral) { remotePeripheral, error in
            guard error == nil else {
                print("Error connecting peripheral: \(String(describing: error))")
                // TODO: can't connect
                return
            }
            if var device = self.modelData?.BTDevice(remotePeripheral) {
                device.updated = NSDate().timeIntervalSince1970
                device.connected = true
            }
            else {
                //
                print("Error: attempting to connect to device which is not detected?")
            }
        }
    }
    
    public func disconnect(_ remotePeripheral : BKRemotePeripheral)
    {
        do {
            try central.disconnectRemotePeripheral(remotePeripheral)
            if var device = self.modelData?.BTDevice(remotePeripheral) {
                device.updated = NSDate().timeIntervalSince1970
                device.connected = false
            }
        }
        catch {
            print("Disconnect error: \(error)")
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// BLE Central Delegate (BKRemotePeripheralDelegate, BKRemotePeerDelegate)

extension CentralDelegate : BKRemotePeripheralDelegate, BKRemotePeerDelegate
{
    // MARK: BKRemotePeripheralDelegate    
    
    private func sendcmd(_ remotePeripheral : BKRemotePeripheral, cmd: String)
    {
        let data = Data(cmd.utf8)
        print("Sending \(cmd) to remote device \(remotePeripheral)")
        central.sendData(data, toRemotePeer: remotePeripheral) { data, remotePeripheral, error in
            guard error == nil else {
                print("Failed sending to \(remotePeripheral)")
                return
            }
            print("ID sent")
        }
    }

    internal func remotePeripheral(_ remotePeripheral: BKRemotePeripheral, didUpdateName name: String)
    {
        print("Name change: \(name)")
        // TODO: remote name changed
    }
    
    internal func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
    {
        print("Received data of length: \(data.count)")
        
        // TODO: encrypt BT data
        if let strid = String(data: data, encoding: .utf8) {
            let index = strid.index(strid.startIndex, offsetBy: 2)
//            if strid[..<index] == "id" {
//                // send my ID-0
//                if let _ = UUID(uuidString: String(strid[index...])) {
//                    // let now = NSDate().timeIntervalSince1970
//                    // add remote device
//                    // if now - (remoteDevices[uuid] ?? 0) > CentralDelegate.REMOTE_TIMEOUT {
//                    // always update time
//                    self.modelData?.BTDeleteExpired()
//                    // respond with
//
//                    // TODO: New device id is exchanged; do something else
//
//                    return
//                }
//            }
            if strid[..<index] == "nm" {
                // TODO: got the remote name
                let name = String(strid[index...])
                if var device = self.modelData?.BTDevice(remotePeer) {
                    device.updated = NSDate().timeIntervalSince1970
                    device.nickname = name
                }
                // return: can now disconnect and ignore this device
            }
            // TODO: process other commands
        }
        // invalid data or already connected; disconnect
        print("Unknown data - disconnecting")
        disconnect(remotePeer as! BKRemotePeripheral)
    }
    
    internal func remotePeripheralIsReady(_ remotePeripheral: BKRemotePeripheral)
    {
        print("Peripheral is ready: \(remotePeripheral)")
        sendcmd(remotePeripheral, cmd: "nm\(self.modelData!.nickname)")
    }
}

extension RangeReplaceableCollection where Element : Equatable
{
    @discardableResult
    mutating func remove(_ element : Element) -> Element?
    {
        if let index = firstIndex(of: element) {
            return remove(at: index)
        }
        return nil
    }
}

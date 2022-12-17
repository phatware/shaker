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
        }
    }
    
    // MARK: BKCentralDelegate
    
    internal func central(_ central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
    {
        print("Remote peripheral did disconnect: \(remotePeripheral)")
        self.modelData?.connectedDevices.remove(remotePeripheral)
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
                    print("Discovery: \(insertedDiscovery) - connecting...")
                    self.connect(insertedDiscovery.discovery.remotePeripheral)
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
        if let connectedDevices = self.modelData?.connectedDevices {
            for cd in connectedDevices {
                if cd == remotePeripheral {
                    // already connected
                    return
                }
            }
        }
        central.connect(remotePeripheral: remotePeripheral) { remotePeripheral, error in
            guard error == nil else {
                print("Error connecting peripheral: \(String(describing: error))")
                // TODO: can't connect
                return
            }
            self.modelData?.connectedDevices.append(remotePeripheral)
        }
    }
    
    public func disconnect(_ remotePeripheral : BKRemotePeripheral)
    {
        do {
            try central.disconnectRemotePeripheral(remotePeripheral)
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
    }
    
    internal func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
    {
        print("Received data of length: \(data.count)")
        
        // TODO: encrypt BT data
        if let strid = String(data: data, encoding: .utf8) {
            let index = strid.index(strid.startIndex, offsetBy: 2)
            if strid[..<index] == "id" {
                // send my ID-0
                if let uuid = UUID(uuidString: String(strid[index...])) {
                    let now = NSDate().timeIntervalSince1970
                    // add remote device
                    // if now - (remoteDevices[uuid] ?? 0) > CentralDelegate.REMOTE_TIMEOUT {
                    // always update time
                    self.modelData?.deleteExpiredDevices()
                    self.modelData?.detectedDevices[uuid] = now
                    // respond with
                    
                    // TODO: New device id is exchanged; do something else
                    
                    return
                }
            }
            else if strid[..<index] == "nm" {
                // TODO: got remote name
                return
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
        sendcmd(remotePeripheral, cmd: "id\(modelData!.deviceid)")
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

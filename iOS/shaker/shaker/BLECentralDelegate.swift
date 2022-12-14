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
    private var remoteDevices: [UUID:TimeInterval] = [:]
    
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
    
    func connect(_ remotePeripheral : BKRemotePeripheral)
    {
        central.connect(remotePeripheral: remotePeripheral) { remotePeripheral, error in
            guard error == nil else {
                print("Error connecting peripheral: \(String(describing: error))")
                // TODO: can't connect
                return
            }
            // TODO: connected to remote peripheral, and send device ID
            self.sendid(remotePeripheral)
        }
    }
    
    func sendid(_ remotePeripheral : BKRemotePeripheral)
    {
        let idcmd: String = "id\(modelData!.deviceid)"
        let data = Data(idcmd.utf8)
        print("Sending \(idcmd) to remote device \(remotePeripheral)")
        central.sendData(data, toRemotePeer: remotePeripheral) { data, remotePeripheral, error in
            guard error == nil else {
                print("Failed sending to \(remotePeripheral)")
                return
            }
            print("ID sent")
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
/// BLE Central Delegate (BKRemotePeripheralDelegate, BKRemotePeerDelegate)

extension CentralDelegate : BKRemotePeripheralDelegate, BKRemotePeerDelegate
{
    // MARK: BKRemotePeripheralDelegate
    static let REMOTE_TIMEOUT : TimeInterval = 12 * 60 * 60
    
    internal func remotePeripheral(_ remotePeripheral: BKRemotePeripheral, didUpdateName name: String)
    {
        print("Name change: \(name)")
    }
    
    internal func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
    {
        print("Received data of length: \(data.count) with hash: \(data)")
        
        if let strid = String(data: data, encoding: .utf8) {
            let index = strid.index(strid.startIndex, offsetBy: 2)
            if strid[..<index] == "id" {
                // send my ID-0
                if let uuid = UUID(uuidString: String(strid[index...])) {
                    let now = NSDate().timeIntervalSince1970
                    // add remote device
                    if now - (remoteDevices[uuid] ?? 0) > CentralDelegate.REMOTE_TIMEOUT {
                        remoteDevices[uuid] = now
                    }
                    // TODO: New device id is exchanged
                }
            }
            // TODO: process other commands
        }
        
    }
    
    internal func remotePeripheralIsReady(_ remotePeripheral: BKRemotePeripheral)
    {
        print("Peripheral ready: \(remotePeripheral)")
    }
}


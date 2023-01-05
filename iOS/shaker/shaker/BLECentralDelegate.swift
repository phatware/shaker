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
    }
    
    private func scan(_ central: BKCentral)
    {
        central.scanContinuouslyWithChangeHandler({ changes, discoveries in
            
            for insertedDiscovery in changes.filter({ $0 == .insert(discovery: nil) }) {
                if let name = insertedDiscovery.discovery.localName, name.lengthOfBytes(using: .utf8) == 24 {
                    if let uuid = self.modelData?.BTDeviceNameToUuid(name) {
                        if let device = self.modelData?.BTDevice(uuid) {
                            self.modelData?.BTDeviceUpdate(device.peer)
                        }
                        else {
                            // add new device to the list and connect to it to get config
                            let remotePeer = insertedDiscovery.discovery.remotePeripheral
                            remotePeer.delegate = self
                            remotePeer.peripheralDelegate = self
                            let new_device = BTDeviceInfo(peer: remotePeer, deviceid: uuid, updated: NSDate().timeIntervalSince1970)
                            self.modelData?.detectedDevices.append(new_device)
                            print("Discovery - new device: \(uuid))")
                            // self.connect(insertedDiscovery.discovery.remotePeripheral)
                        }
                    }
                }
            }
        }, stateHandler: { newState in
            if newState == .scanning {
                // TODO: scanning...
                print("Scanning for peripherals")
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

            // if let device = self.modelData?.BTDevice(remotePeripheral) {
            guard error == nil else {
                print("Error connecting peripheral: \(String(describing: error))")
                // TODO: can't connect
                return
            }
            print("Connected remote Peripheral")
            // self.sendcmd(remotePeripheral, cmd: "nm\(self.modelData!.nickname)")
        }
    }
    
    public func disconnect(_ remotePeripheral : BKRemotePeripheral)
    {
        print("Will disconnect remote Peripheral")
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
        // TODO: remote name changed
    }
    
    internal func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
    {
        print("Received data of length: \(data.count)")
        
        // invalid data or already connected; disconnect
        print("Unknown data - disconnecting")
        disconnect(remotePeer as! BKRemotePeripheral)
    }
    
    internal func remotePeripheralIsReady(_ remotePeripheral: BKRemotePeripheral)
    {
        print("Peripheral is ready: \(remotePeripheral)")
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

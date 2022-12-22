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
    private var onStateChange: ((ShakerModel, BKCentral.ContinuousScanState) -> Void)? = nil
    
    init(onStateChange: ((ShakerModel, BKCentral.ContinuousScanState) -> Void)?)
    {
        self.onStateChange = onStateChange
    }

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
        self.modelData?.BTDevice(remotePeripheral, setState: .disconnected)
    }
    
    private func scan(_ central: BKCentral)
    {
        central.scanContinuouslyWithChangeHandler({ changes, discoveries in
            
            for insertedDiscovery in changes.filter({ $0 == .insert(discovery: nil) }) {
                if let name = insertedDiscovery.discovery.localName, name.lengthOfBytes(using: .utf8) == 24 {
                    if let uuid = self.modelData?.BTDeviceNameToUuid(name) {
                        if let device = self.modelData?.BTDevice(uuid) {
                            
                            // already discovered, update time
                            if device.state == .disconnected {
                                // try to connect again
                                print("Discovery: \(String(describing: insertedDiscovery.discovery.localName)) - connecting...")
                                // reconnect, if disconnected
                                self.modelData?.BTDevice(device.peer, setState: .connecting)
                                self.connect(insertedDiscovery.discovery.remotePeripheral)
                            }
                            else if device.state == .configured {
                                self.modelData?.BTDeviceUpdate(device.peer)
                            }
                            else if device.state == .ignored {
                                self.modelData?.BTDeviceUpdate(device.peer)
                            }
                            continue
                        }
                        // add new device to the list and connect to it to get config
                        let remotePeer = insertedDiscovery.discovery.remotePeripheral
                        remotePeer.delegate = self
                        remotePeer.peripheralDelegate = self
                        var new_device = BTDeviceInfo(peer: remotePeer, deviceid: uuid, updated: NSDate().timeIntervalSince1970)
                        self.modelData?.detectedDevices.append(new_device)
                        new_device.state = .connecting
                        print("Discovery: \(String(describing: insertedDiscovery.discovery.localName)) - connecting...")
                        self.connect(insertedDiscovery.discovery.remotePeripheral)
                    }
                }
            }
            
        }, stateHandler: { newState in
            if let onStateChange = self.onStateChange, let model = self.modelData {
                onStateChange(model, newState)
            }
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

            if let device = self.modelData?.BTDevice(remotePeripheral) {

                guard error == nil else {
                    print("Error connecting peripheral: \(String(describing: error))")
                    // TODO: can't connect
                    if device.state == .connecting {
                        self.modelData?.BTDevice(remotePeripheral, setState: .disconnected)
                    }
                    return
                }
                print("Connected remote Peripheral")
                self.modelData?.BTDevice(remotePeripheral, setState: .connected)
                // self.sendcmd(remotePeripheral, cmd: "nm\(self.modelData!.nickname)")
            }
            else {
                //
                print("Error: attempting to connect to device which is not detected?")
            }
        }
    }
    
    public func disconnect(_ remotePeripheral : BKRemotePeripheral)
    {
        print("Will disconnect remote Peripheral")
        do {
            try central.disconnectRemotePeripheral(remotePeripheral)
            self.modelData?.BTDevice(remotePeripheral, setState: .disconnected)
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
            if strid[..<index] == "nm" {
                let name = String(strid[index...])
                if let modelData = self.modelData {
                    modelData.BTDevice(remotePeer, setName: name)
                    // the device is now configured
                    modelData.BTDevice(remotePeer, setState: .configured)
                    // send ID and local name back to peripheral
                    let cmd = String("in\(modelData.localName())\(modelData.nickname)")
                    self.sendcmd(remotePeer as! BKRemotePeripheral, cmd: cmd)
                    
                }
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

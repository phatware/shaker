//
//  BLEPeripheralDelegatge.swift
//  shaker
//
//  Created by Stan Miasnikov on 12/13/22.
//

import Foundation
import CoreLocation
import CoreBluetooth

///////////////////////////////////////////////////////////////////////////////////////////
/// BLE Peripheral Delegate (BKPeripheralDelegate, BKAvailabilityObserver, BKRemotePeerDelegate)

class PeripheralDelegatge : BKPeripheralDelegate, BKAvailabilityObserver, BKRemotePeerDelegate
{
    private var modelData: ShakerModel?
    private let peripheral = BKPeripheral()
    
    
    deinit {
        _ = try? peripheral.stop()
    }
    
    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability)
    {
        // TODO: implement
        
    }
    
    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause)
    {
        // TODO: implement
        
    }
    
    func startPeripheral(_ modelData: ShakerModel)
    {
        do {
            self.modelData = modelData
            peripheral.delegate = self
            peripheral.addAvailabilityObserver(self)
            let dataServiceUUID = UUID(uuidString: "C2436366-6B33-456E-9DA1-6394D9601C4C")!
            let dataServiceCharacteristicUUID = UUID(uuidString: "ECF0C0D1-FB70-43AA-B4D5-6B2B048D55CF")!
            let configuration = BKPeripheralConfiguration(dataServiceUUID: dataServiceUUID, dataServiceCharacteristicUUID: dataServiceCharacteristicUUID, localName: modelData.localName())
            try peripheral.startWithConfiguration(configuration)
            print("Awaiting connections from remote centrals")
        } catch let error {
            print("Error starting: \(error)")
        }
    }
    
    private func sendcmd(_ remoteCentral : BKRemotePeer, cmd: String)
    {
        let data = Data(cmd.utf8)
        peripheral.sendData(data, toRemotePeer: remoteCentral) { data, remoteCentral, error in
            guard error == nil else {
                print("Failed sending to \(remoteCentral)")
                return
            }
            print("Sent to \(remoteCentral)")
        }
    }
    
//    @objc private func sendData() {
//        let numberOfBytesToSend: Int = Int(arc4random_uniform(950) + 50)
//        let data = Data.dataWithNumberOfBytes(numberOfBytesToSend)
//        Logger.log("Prepared \(numberOfBytesToSend) bytes with MD5 hash: \(data.md5().toHexString())")
//        for remoteCentral in peripheral.connectedRemoteCentrals {
//            Logger.log("Sending to \(remoteCentral)")
//            peripheral.sendData(data, toRemotePeer: remoteCentral) { data, remoteCentral, error in
//                guard error == nil else {
//                    Logger.log("Failed sending to \(remoteCentral)")
//                    return
//                }
//                Logger.log("Sent to \(remoteCentral)")
//            }
//        }
//    }

    
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral)
    {
        print("Remote central did connect: \(remoteCentral)")
        remoteCentral.delegate = self
        self.modelData?.BTDevice(remoteCentral, setState: .connected)
        self.sendcmd(remoteCentral, cmd: "nm\(self.modelData!.nickname)")
    }
    
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral)
    {
        print("Remote central did disconnect: \(remoteCentral)")
        self.modelData?.BTDevice(remoteCentral, setState: .disconnected)
        self.modelData?.BTDeleteExpired()
    }
    
    func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
    {
        print("Received data of length: \(data.count) with data: \(data)")
        
        if let strid = String(data: data, encoding: .utf8) {
            let index: String.Index = strid.index(strid.startIndex, offsetBy: 2)
            // TODO: got data from central
            if strid[..<index] == "in", strid.lengthOfBytes(using: .utf8) > 26 {
                let index2: String.Index = strid.index(strid.startIndex, offsetBy: 26)
                let idstr = String(strid[index..<index2])
                let nickname = String(strid[index2...])
                if let uuid = self.modelData?.BTDeviceNameToUuid(idstr) {
                    if var device = self.modelData?.BTDevice(uuid) {
                        self.modelData?.BTDevice(device.peer, setName: nickname)
                    }
                    else {
                        // add new device to the list and connect to it to get config
                        var new_device = BTDeviceInfo(peer: remotePeer, deviceid: uuid, updated: NSDate().timeIntervalSince1970)
                        new_device.state = .connected
                        new_device.nickname = nickname
                        self.modelData?.detectedDevices.append(new_device)
                    }
                }
            }
        }
    }
    
}


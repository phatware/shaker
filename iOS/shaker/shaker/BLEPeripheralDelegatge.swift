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
        stop()
    }
    
    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability)
    {
        // TODO: implement
        
    }
    
    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause)
    {
        // TODO: implement
        
    }
    
    func stop()
    {
        _ = try? peripheral.stop()
    }
    
    func startPeripheral(_ modelData: ShakerModel)
    {
        do {
            self.modelData = modelData
            peripheral.delegate = self
            peripheral.addAvailabilityObserver(self)
            let dataServiceUUID = UUID(uuidString: "C2436366-6B33-456E-9DA1-6394D9601C4C")!
            let dataServiceCharacteristicUUID = UUID(uuidString: "ECF0C0D1-FB70-43AA-B4D5-6B2B048D55CF")!
            let configuration = BKPeripheralConfiguration(dataServiceUUID: dataServiceUUID,
                                                          dataServiceCharacteristicUUID: dataServiceCharacteristicUUID,
                                                          localName: modelData.localName())
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
    
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral)
    {
        print("Remote central did connect: \(remoteCentral)")
        remoteCentral.delegate = self
    }
    
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral)
    {
        print("Remote central did disconnect: \(remoteCentral)")
    }
    
    func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
    {
        print("Received data of length: \(data.count) with data: \(data)")                
    }
}


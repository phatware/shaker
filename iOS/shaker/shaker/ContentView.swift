//
//  ContentView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import SwiftUI
import MapKit
import CoreLocation
import CoreBluetooth

enum SearchScope: String, CaseIterable
{
    case alcoholic, alcoholfree
}

struct CoctailRow: View
{
    @EnvironmentObject var modelData: ShakerModel
    var rec_id: Int64

    private var name : String {
        return modelData.database.getRecipeName(rec_id, alcohol: true)?["name"] as? String ?? "(Unknown)"
    }
    
    var body: some View {
        NavigationLink(destination: Text(name)) {
            Text(name)
                .searchCompletion(name)
                .foregroundColor(.black)
        }
    }
}

struct CoctailsView: View
{
    @EnvironmentObject var modelData: ShakerModel

    @State private var searchText = ""
    @State private var column = "name"
    
    private var filter: String {
        return "\(column) LIKE '%\(searchText)%'"
    }
    
    private var alcoholic: [Int64] {
        if searchText.isEmpty {
            return modelData.database.getUnlockedRecordList(true, filter: nil, addName: false) as? [Int64] ?? []
        }
        else {
            return modelData.database.getUnlockedRecordList(true, filter: self.filter, addName: false) as? [Int64] ?? []
        }
    }
    private var non_alcoholic: [Int64] {
        if searchText.isEmpty {
            return modelData.database.getUnlockedRecordList(false, filter: nil, addName: false) as? [Int64] ?? []
        }
        else {
            return modelData.database.getUnlockedRecordList(false, filter: self.filter, addName: false) as? [Int64] ?? []
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(alcoholic, id: \.self) { rec_id in
                        CoctailRow(rec_id: rec_id)
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer) {
                    //                ForEach(SearchScope.allCases, id: \.self) { scope in
                    //                    Text(scope.rawValue.capitalized)
                    //                }
                }
                .listStyle(InsetListStyle())
            }
            .navigationTitle("Coctails")
        }
    }
}

struct PlayView: View
{
    var body: some View {
        Text("Play!")
    }
}

struct AccountView: View
{
    var body: some View {
        Text("Account")
    }
}

struct ContentView: View
{
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var modelData: ShakerModel
    
    private let central = CentralDelegate()
    private let peripheral = PeripheralDelegatge()

    var body: some View {
        TabView {
            CoctailsView()
                .tabItem {
                    Label("Coctails", systemImage: "wineglass")
                    Text("Coctails")
                }
            IngredientsView()
                .tabItem {
                    Label("Ingredients", systemImage: "checklist")
                    Text("Ingredients")
                }
            PlayView()
                .tabItem {
                    Label("Play!", systemImage: "gamecontroller")
                    Text("Play!")
                }
            MapContentView()
                .tabItem {
                    Label("Map", systemImage: "map")
                    Text("Map")
                }
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person")
                    Text("Account")
                }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                LocationService.shared.requestLocation()
            } else if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .background {
                print("Background")
            }
        }
        .navigationTitle("Shaker")
        .onAppear() {
            central.startCentral()
            peripheral.startPeripheral()
        }
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View {
        ContentView()
            .environmentObject(ShakerModel())
    }
}

class CentralDelegate : BKCentralDelegate, BKAvailabilityObserver
{
    @EnvironmentObject var modelData: ShakerModel
    private var discoveries = [BKDiscovery]()
    private let central = BKCentral()
    private var remoteDevices: [UUID:TimeInterval] = [:]
    
    func startCentral()
    {
        do {
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
    
    internal func central(_ central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral) {
        print("Remote peripheral did disconnect: \(remotePeripheral)")
    }
    
    private func scan(_ central: BKCentral) {
        central.scanContinuouslyWithChangeHandler({ changes, discoveries in
            let indexPathsToRemove = changes.filter({ $0 == .remove(discovery: nil) }).map({ IndexPath(row: self.discoveries.firstIndex(of: $0.discovery)!, section: 0) })
            self.discoveries = discoveries
            let indexPathsToInsert = changes.filter({ $0 == .insert(discovery: nil) }).map({ IndexPath(row: self.discoveries.firstIndex(of: $0.discovery)!, section: 0) })
            if !indexPathsToRemove.isEmpty {
                // TODO: self.discoveriesTableView.deleteRows(at: indexPathsToRemove, with: UITableView.RowAnimation.automatic)
            }
            if !indexPathsToInsert.isEmpty {
                // TODO: self.discoveriesTableView.insertRows(at: indexPathsToInsert, with: UITableView.RowAnimation.automatic)
            }
            for insertedDiscovery in changes.filter({ $0 == .insert(discovery: nil) }) {
                print("Discovery: \(insertedDiscovery)")
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
            
            
        }

    }
    
    func sendid(_ remotePeripheral : BKRemotePeripheral)
    {
        let idcmd: String = "id\(modelData.deviceid)"
        let data = Data(idcmd.utf8)
        central.sendData(data, toRemotePeer: remotePeripheral) { data, remotePeripheral, error in
            guard error == nil else {
                print("Failed sending to \(remotePeripheral)")
                return
            }
            print("Sent id to \(remotePeripheral)")
            
        }
    }

}

extension CentralDelegate : BKRemotePeripheralDelegate, BKRemotePeerDelegate
{
    // MARK: BKRemotePeripheralDelegate
    static let REMOTE_TIMEOUT : TimeInterval = 12 * 60 * 60
    
    internal func remotePeripheral(_ remotePeripheral: BKRemotePeripheral, didUpdateName name: String) {
        print("Name change: \(name)")
    }
    
    internal func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data) {
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
    
    internal func remotePeripheralIsReady(_ remotePeripheral: BKRemotePeripheral) {
        print("Peripheral ready: \(remotePeripheral)")
    }
}


class PeripheralDelegatge : BKPeripheralDelegate, BKAvailabilityObserver, BKRemotePeerDelegate
{
    @EnvironmentObject var modelData: ShakerModel
    
    private let peripheral = BKPeripheral()
    private var remoteDevices: [UUID:TimeInterval] = [:]

    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability)
    {
        // TODO: implement

    }
    
    func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause)
    {
        // TODO: implement

    }
    
    
    func startPeripheral() {
        do {
            peripheral.delegate = self
            peripheral.addAvailabilityObserver(self)
            let dataServiceUUID = UUID(uuidString: "C2436366-6B33-456E-9DA1-6394D9601C4C")!
            let dataServiceCharacteristicUUID = UUID(uuidString: "ECF0C0D1-FB70-43AA-B4D5-6B2B048D55CF")!
            let localName = Bundle.main.infoDictionary!["CFBundleName"] as? String
            let configuration = BKPeripheralConfiguration(dataServiceUUID: dataServiceUUID, dataServiceCharacteristicUUID: dataServiceCharacteristicUUID, localName: localName)
            try peripheral.startWithConfiguration(configuration)
            print("Awaiting connections from remote centrals")
        } catch let error {
            print("Error starting: \(error)")
        }
    }

    func sendid(_ remoteCentral : BKRemotePeer)
    {
        let idcmd: String = "id\(modelData.deviceid)"
        let data = Data(idcmd.utf8)
        peripheral.sendData(data, toRemotePeer: remoteCentral) { data, remoteCentral, error in
            guard error == nil else {
                print("Failed sending to \(remoteCentral)")
                return
            }
            print("Sent to \(remoteCentral)")
        }
    }
    
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral) {
        print("Remote central did connect: \(remoteCentral)")
        // TODO: implement
        
    }
    
    func peripheral(_ peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral) {
        print("Remote central did disconnect: \(remoteCentral)")
        // TODO: implement
    }
    
    func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data) {
        print("Received data of length: \(data.count) with data: \(data)")

        if let strid = String(data: data, encoding: .utf8) {
            let index: String.Index = strid.index(strid.startIndex, offsetBy: 2)
            if strid[..<index] == "id" {
                // send my ID
                // register UUID
                if let uuid = UUID(uuidString: String(strid[index...])) {
                    let now = NSDate().timeIntervalSince1970
                    // add remote device
                    if now - (remoteDevices[uuid] ?? 0) > CentralDelegate.REMOTE_TIMEOUT {
                        remoteDevices[uuid] = now
                    }
                    sendid(remotePeer)
                }
                else {
                    print("Invalid device id received; will ignore the device")
                }
            }
            // TODO: process other commands
        }
    }

}

//extension StringProtocol {
//    subscript(offset: Int) -> Character {
//        self[index(startIndex, offsetBy: offset)]
//    }
//}


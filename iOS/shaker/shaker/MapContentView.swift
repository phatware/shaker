//
//  MapView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import SwiftUI
import CoreLocation
import MapKit

struct MapContentView: View {
    
    let type: MKMapType = .standard
    @State var region: MKCoordinateRegion?
    let trackingMode: MKUserTrackingMode = .none
    @State var pushDetail = false
    @State var selectedItam : MKMapItem?
    
    var body: some View {
        NavigationView {
            VStack {
                MapView(mapType: self.type,
                        region: self.$region,
                        publish: self.$pushDetail,
                        selectedItam: self.$selectedItam,
                        userTrackingMode: self.trackingMode)
                .edgesIgnoringSafeArea(.top)
                
                //            if self.region != nil {
                //                Text("\( self.regionToString(self.region!) )")
                //            }
                NavigationLink(isActive: $pushDetail) {
                    MapDetails(mapItem: selectedItam)
                } label: {
                    EmptyView()
                }
            }
            .onAppear {
                // this is required to display the user's current location
                self.requestLocationUsage()
                if let coord = LocationService.shared.currentLocation?.coordinate {
                    region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
                }
            }
        }
        
    }
    
    func regionToString(_ region: MKCoordinateRegion) -> String {
        "\(region.center.latitude), \(region.center.longitude)"
    }
    
    let locationManager = CLLocationManager()
    private func requestLocationUsage() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    
}

#if DEBUG
struct MapContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
    
}
#endif


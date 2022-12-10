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
    
    private let type: MKMapType = .standard
    private let trackingMode: MKUserTrackingMode = .none
    @State private var region: MKCoordinateRegion?
    @State private var pushDetail = false
    @State private var pushSearch = false
    @State private var selectedItem : MKMapItem?
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack {
                    MapView(mapType: self.type,
                            region: self.$region,
                            publish: self.$pushDetail,
                            selectedItam: self.$selectedItem,
                            userTrackingMode: self.trackingMode)
                    .edgesIgnoringSafeArea(.top)
                    
                    NavigationLink(isActive: $pushDetail) {
                        MapDetails(mapItem: selectedItem)
                    } label: {
                        EmptyView()
                    }
                    NavigationLink(isActive: $pushSearch) {
                        MapSearchView()
                    } label: {
                        EmptyView()
                    }
                }
                Button(role: .none) {
                    // TODO: search
                    print("Search map")
                    pushSearch = true
                } label: {
                    HStack {
                        Image(systemName: "location.magnifyingglass")
                            .font(.headline)
                        Text("Search")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                // .padding(.top, 5)
                .padding(.bottom, 15)
            }
            .onAppear {
                // this is required to display the user's current location
                self.requestLocationUsage()
                if let coord = LocationService.shared.currentLocation?.coordinate {
                    region = MKCoordinateRegion(center: coord,
                                                span: MKCoordinateSpan.fromMeters(coord.latitude,
                                                                                  lat_meters: Double.DELTA_LAT_METERS,
                                                                                  lon_meters: Double.DELTA_LON_METERS))
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


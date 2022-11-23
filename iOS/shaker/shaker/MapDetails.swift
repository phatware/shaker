//
//  Details.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/20/22.
//

import SwiftUI
import MapKit

struct MapDetails: View {
    
    var mapItem: MKMapItem?
    private let delta = 0.005
    
    let defCoord : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Text(mapItem?.name ?? "Point of Interest")
                .font(.headline)
                .padding(.top, 5)
                .padding(.bottom, 5)
            Text(mapItem?.placemark.formattedAddress ?? "")
                .font(.subheadline)
                .padding(.top, 5)
                .padding(.bottom, 5)
            if let phone = mapItem?.phoneNumber {
                let tel = "tel:" + phone.replacingOccurrences(of: " ", with: "")
                Link(phone, destination: URL(string: tel)!)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                // .font(.footnote)
            }
            if let url = mapItem?.url?.absoluteString {
                Link(destination: URL(string: url)!) {
                    Text(url)
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, 5)
                .padding(.bottom, 5)
            }
        }
        .padding(.leading, 15)
        VStack(alignment: .center) {
            ZStack(alignment: .bottom) {
                                
                MapView(mapType: .standard,
                        region: .constant(region),
                        publish: .constant(false),
                        selectedItam: .constant(nil),
                        isZoomEnabled: true,
                        isScrollEnabled: true,
                        isRotateEnabled: true,
                        showsUserLocation: true,
                        userTrackingMode: .none,
                        annotations: [annotation]
                )
                .padding(.leading, 5)
                .padding(.trailing, 5)
                .padding(.top, 5)
                .padding(.bottom, 5)

                Button(role: .none) {
                    self.mapItem?.openInMaps(launchOptions: nil)
                } label: {
                    HStack {
                        Image(systemName: "map")
                            .font(.headline)
                        Text("Open in Maps")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .padding(.top, 5)
                .padding(.bottom, 15)
            }
        }
        .navigationTitle(mapItem?.name ?? "Point of Interest")
    }
    
    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: mapItem?.placemark.coordinate ?? defCoord,
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        )
    }
    
    var annotation: CustomAnnotation {
        CustomAnnotation( title: mapItem?.name ?? "Point of Interest",
                          coordinate: mapItem?.placemark.coordinate ?? defCoord,
                          type: mapItem?.pointOfInterestCategory ?? .restaurant)
    }

    
}

struct MapDetails_Previews: PreviewProvider {
    static var previews: some View {
        MapDetails(mapItem: nil)
    }
}

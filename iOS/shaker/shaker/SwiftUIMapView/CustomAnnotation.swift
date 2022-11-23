//
//  CustomAnnotation.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import MapKit
import CoreLocation

class CustomAnnotation: NSObject, MapViewAnnotation, Identifiable {
    
    let coordinate: CLLocationCoordinate2D
    
    let title: String?
    
    let id = UUID()
    
    let type: MKPointOfInterestCategory
    
    let clusteringIdentifier: String? = "shaker"
    
    let glyphImage: UIImage?
    
    let tintColor: UIColor? = .green
    
    init(title: String, coordinate: CLLocationCoordinate2D, type: MKPointOfInterestCategory = .restaurant) {
        self.title = title
        self.coordinate = coordinate
        self.type = type
        self.glyphImage = UIImage(systemName: type.symbolName)
    }
    
}

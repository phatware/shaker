//
//  MKMapView+MapViewAnnotation.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import MapKit

extension MKMapView {
    
    /**
     All `MapAnnotations` set on the map view.
     */
    var mapViewAnnotations: [MapViewAnnotation] {
        annotations.compactMap { $0 as? MapViewAnnotation }
    }
    
    /**
     All `MapAnnotations` selected on the map view.
     */
    var selectedMapViewAnnotations: [MapViewAnnotation] {
        selectedAnnotations.compactMap { $0 as? MapViewAnnotation }
    }
    
}

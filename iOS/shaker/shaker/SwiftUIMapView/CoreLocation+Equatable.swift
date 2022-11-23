//
//  CoreLocation+Equatable.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import Foundation
import CoreLocation
import MapKit

extension CLLocationCoordinate2D: Equatable
{
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKCoordinateSpan: Equatable
{
    public static func ==(lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }

}

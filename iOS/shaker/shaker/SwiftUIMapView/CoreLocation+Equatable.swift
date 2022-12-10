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
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool
    {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    static public func defaultCoords() -> CLLocationCoordinate2D
    {
        // default coords of SF warf
        return CLLocationCoordinate2D(latitude: 37.7810998, longitude: -122.3948319)
    }
}

extension MKCoordinateSpan: Equatable
{
    public static func ==(lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool
    {
        lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }

}

extension MKCoordinateSpan
{
    static public func fromMeters(_ lat: CLLocationDegrees, lat_meters: Double, lon_meters: Double) -> MKCoordinateSpan
    {
        func degreesToRadians(_ x: Double) -> Double
        {
            return (Double.pi * (x) / 180.0)
        }
        let lat_delta = lat_meters * Double.LAT_METER_TO_DEGREE
        let tanDegrees = tan(degreesToRadians(lat));
        let beta =  tanDegrees * Double.WGS84_CONSTANT;
        
        let lengthOfDegree = cos(atan(beta)) * Double.EARTH_EQUATORIAL_RADIUS * Double.pi / 180.0
        let lon_delta = lon_meters/lengthOfDegree

        return MKCoordinateSpan(latitudeDelta: lat_delta, longitudeDelta: lon_delta)
    }
}

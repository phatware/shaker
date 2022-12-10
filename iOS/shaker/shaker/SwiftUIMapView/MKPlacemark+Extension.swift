//
//  MKPlacemark+Extension.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/20/22.
//


import MapKit
import Contacts

extension MKPlacemark
{
    var formattedAddress: String? {
                
        guard let postalAddress = postalAddress else { return nil }
        let mpa : CNMutablePostalAddress = CNMutablePostalAddress()
        mpa.street = postalAddress.street
        mpa.city = postalAddress.city
        mpa.state = postalAddress.state
        mpa.postalCode = postalAddress.postalCode
        mpa.country = ""    // do not inclure coutry name with the formatted address
        return CNPostalAddressFormatter.string(from: mpa, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
    }
}

// MAP constants 

extension Double
{
    public static let EARTH_EQUATORIAL_RADIUS = 6378137.0
    public static let WGS84_CONSTANT = 0.99664719
    public static let METERS_IN_MILE = 1609.344
    public static let DELTA_LAT_METERS = METERS_IN_MILE/2.0
    public static let DELTA_LON_METERS = METERS_IN_MILE/2.0
    public static let LAT_METER_TO_DEGREE = 0.0045 / 500.0
}

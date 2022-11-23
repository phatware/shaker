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
        return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
    }
}

//
//  MKPointOfInterestCategory+Extension.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import Foundation
import MapKit

extension MKPointOfInterestCategory
{    
    static let drinkPointsOfInterest: [MKPointOfInterestCategory] = [.brewery, .cafe, .restaurant, .winery, .nightlife]
    static let storePointsOfInterest: [MKPointOfInterestCategory] = [.store]
    static let defaultPointOfInterestSymbolName = "mappin.and.ellipse"
    
    var symbolName: String {
        switch self {
        case .airport:
            return "airplane"
        case .atm, .bank:
            return "banknote"
        case .bakery, .brewery, .foodMarket, .restaurant:
            return "fork.knife"
        case .cafe:
            return "cup.and.saucer"
        case .winery:
            return "wineglass"
        case .campground, .hotel:
            return "bed.double"
        case .carRental, .evCharger, .gasStation, .parking:
            return "car"
        case .store:
            return "bag"
        case .laundry:
            return "tshirt"
        case .library, .museum, .school, .theater, .university:
            return "building.columns"
        case .nationalPark, .park:
            return "leaf"
        case .postOffice:
            return "envelope"
        case .publicTransport:
            return "bus"
        case .nightlife:
            return "party.popper"
        default:
            return MKPointOfInterestCategory.defaultPointOfInterestSymbolName
        }
    }
}

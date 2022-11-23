/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A singleton object that handles requesting and updating the user location.
*/

import Foundation
import CoreLocation
import UIKit

class LocationService: NSObject
{    
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    /// This property is  `@objc` so that the view controllers can observe when the user location changes through key-value observing.
    @objc dynamic var currentLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    private func displayLocationServicesDeniedAlert() {
        
        UIAlertController.showMessage("Location services are denied", withTitle: "Location Services", withSettings: true)
    }
}

extension LocationService: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = locationManager.authorizationStatus
        if status == .denied {
            displayLocationServicesDeniedAlert()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle any errors that `CLLocationManager` returns.
    }
}

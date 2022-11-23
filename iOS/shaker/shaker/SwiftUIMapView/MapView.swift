//
//  MapView.swift
//  shaker
//
//  Created by Stan Miasnikov on 11/19/22.
//

import SwiftUI
import MapKit
import Combine
import UIKit

/**
 Displays a map. The contents of the map are provided by the Apple Maps service.
 
 See the [official documentation](https://developer.apple.com/documentation/mapkit/mkmapview) for more information on the possibilities provided by the underlying service.
 
 - Author: Sören Gade
 - Copyright: 2020—2022 Sören Gade
 */

public struct MapView: UIViewRepresentable
{    
    
    // MARK: Properties
    /**
     The map type that is displayed.
     */
    let mapType: MKMapType
    
    /**
     The region that is displayed.
     
    Note: The region might not be used as-is, as it might need to be fitted to the view's bounds. See [regionThatFits(_:)](https://developer.apple.com/documentation/mapkit/mkmapview/1452371-regionthatfits).
     */
    @Binding var region: MKCoordinateRegion?
    
    @Binding var publish: Bool
    
    @Binding var selectedItem: MKMapItem?

    /**
     Determines whether the map can be zoomed.
    */
    let isZoomEnabled: Bool

    /**
     Determines whether the map can be scrolled.
    */
    let isScrollEnabled: Bool
 
    /**
     Determines whether the map can be rotated.
    */
    let isRotateEnabled: Bool
    
    /**
     Determines whether the current user location is displayed.
     
     This requires the `NSLocationWhenInUseUsageDescription` key in the Info.plist to be set. In addition, you need to call [`CLLocationManager.requestWhenInUseAuthorization()`](https://developer.apple.com/documentation/corelocation/cllocationmanager/1620562-requestwheninuseauthorization) to request for permission.
     */
    let showsUserLocation: Bool
    
    /**
     Sets the map's user tracking mode.
     */
    let userTrackingMode: MKUserTrackingMode
    
    /**
     Annotations that are displayed on the map.
     
     See the `selectedAnnotation` binding for more information about user selection of annotations.
     
     - SeeAlso: selectedAnnotation
     */
    let annotations: [MapViewAnnotation]
    
    /**
     The currently selected annotations.
     
     When the user selects annotations on the map the value of this binding changes.
     Likewise, setting the value of this binding to a value selects the given annotations.
     */
    @Binding var selectedAnnotations: [MapViewAnnotation]
    
    // MARK: Initializer
    /**
     Creates a new MapView.
     
     - Parameters:
        - mapType: The map type to display.
        - region: The region to display.
        - showsUserLocation: Whether to display the user's current location.
        - userTrackingMode: The user tracking mode.
        - annotations: A list of `MapAnnotation`s that should be displayed on the map.
        - selectedAnnotation: A binding to the currently selected annotation, or `nil`.
     */
    public init(mapType: MKMapType = .standard,
                region: Binding<MKCoordinateRegion?> = .constant(nil),
                publish: Binding<Bool> = .constant(false),
                selectedItam: Binding<MKMapItem?> = .constant(nil),
                isZoomEnabled: Bool = true,
                isScrollEnabled: Bool = true,
                isRotateEnabled: Bool = true,
                showsUserLocation: Bool = true,
                userTrackingMode: MKUserTrackingMode = .none,
                annotations: [MapViewAnnotation] = [],
                selectedAnnotations: Binding<[MapViewAnnotation]> = .constant([])) {
        self.mapType = mapType
        self._region = region
        self._publish = publish
        self._selectedItem = selectedItam
        self.isZoomEnabled = isZoomEnabled
        self.isScrollEnabled = isScrollEnabled
        self.isRotateEnabled = isRotateEnabled
        self.showsUserLocation = showsUserLocation
        self.userTrackingMode = userTrackingMode
        self.annotations = annotations
        self._selectedAnnotations = selectedAnnotations
    }

    // MARK: - UIViewRepresentable
    public func makeCoordinator() -> MapView.Coordinator {
        return Coordinator(for: self)
    }

    public func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        // create view
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        // register custom annotation view classes
        mapView.register(MapAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(MapAnnotationClusterView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        // configure initial view state
        configureView(mapView, context: context)

        return mapView
    }

    public func updateUIView(_ mapView: MKMapView, context: UIViewRepresentableContext<MapView>) {
        // configure view update
        configureView(mapView, context: context)
    }

    // MARK: - Configuring view state
    /**
     Configures the `mapView`'s state according to the current view state.
     */
    private func configureView(_ mapView: MKMapView, context: UIViewRepresentableContext<MapView>) {
        // basic map configuration
        mapView.mapType = mapType
        if let mapRegion = region {
            let region = mapView.regionThatFits(mapRegion)
            
            if region.center != mapView.region.center || region.span != mapView.region.span {
                mapView.setRegion(region, animated: true)
            }
        }
        mapView.isZoomEnabled = isZoomEnabled
        mapView.isScrollEnabled = isScrollEnabled
        mapView.isRotateEnabled = isRotateEnabled
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = userTrackingMode
        
        mapView.selectableMapFeatures = [.pointsOfInterest]
        
        let mapConfiguration = MKStandardMapConfiguration()
        mapConfiguration.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.drinkPointsOfInterest)
        
        mapView.preferredConfiguration = mapConfiguration
        
        // annotation configuration
        if !annotations.isEmpty {
            updateAnnotations(in: mapView)
            updateSelectedAnnotation(in: mapView)
        }
    }
    
    /**
     Updates the annotation property of the `mapView`.
     Calculates the difference between the current and new states and only executes changes on those diff sets.
     
     - Parameter mapView: The `MKMapView` to configure.
     */
    private func updateAnnotations(in mapView: MKMapView) {
        let currentAnnotations = mapView.mapViewAnnotations
        // remove old annotations
        let obsoleteAnnotations = currentAnnotations.filter { mapAnnotation in
            !annotations.contains { $0.isEqual(mapAnnotation) }
        }
        mapView.removeAnnotations(obsoleteAnnotations)
        
        // add new annotations
        let newAnnotations = annotations.filter { mapViewAnnotation in
            !currentAnnotations.contains { $0.isEqual(mapViewAnnotation) }
        }
        mapView.addAnnotations(newAnnotations)
    }
    
    /**
     Updates the selection annotations of the `mapView`.
     Calculates the difference between the current and new selection states and only executes changes on those diff sets.
     
     - Parameter mapView: The `MKMapView` to configure.
     */
    private func updateSelectedAnnotation(in mapView: MKMapView) {
        // deselect annotations that are not currently selected
        let oldSelections = mapView.selectedMapViewAnnotations.filter { oldSelection in
            !selectedAnnotations.contains {
                oldSelection.isEqual($0)
            }
        }
        for annotation in oldSelections {
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        // select all new annotations
        let newSelections = selectedAnnotations.filter { selection in
            !mapView.selectedMapViewAnnotations.contains {
                selection.isEqual($0)
            }
        }
        for annotation in newSelections {
            mapView.selectAnnotation(annotation, animated: true)
        }
    }
    
    // MARK: - Interaction and delegate implementation
    public class Coordinator: NSObject, MKMapViewDelegate {
        
        /**
         Reference to the SwiftUI `MapView`.
        */
        private var context: MapView
        
        init(for context: MapView) {
            self.context = context
            super.init()
        }
        
        // MARK: MKMapViewDelegate
        public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let mapAnnotation = view.annotation as? MapViewAnnotation else {
                return
            }
            
            DispatchQueue.main.async {
                self.context.selectedAnnotations.append(mapAnnotation)
            }
        }
        
        public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard let mapAnnotation = view.annotation as? MapViewAnnotation else {
                return
            }
            
            guard let index = context.selectedAnnotations.firstIndex(where: { $0.isEqual(mapAnnotation) }) else {
                return
            }
            
            DispatchQueue.main.async {
                self.context.selectedAnnotations.remove(at: index)
            }
        }
        
        public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.context.region = mapView.region
            }
        }
        
        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let annotation = annotation as? MKMapFeatureAnnotation {
                // Provide a customized annotation view for a tapped point of interest.
                return setupPointOfInterestAnnotation(mapView, annotation:annotation)
            }
            else {
                return nil
            }
        }
        
        public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            
            if let annotation = view.annotation, annotation.isKind(of: MKMapFeatureAnnotation.self) {
                // TODO: open details window
                // mapView.parentViewController?.navigationController?.pushViewController(MapDetails, animated: true)
                guard let selectedAnnotation = mapView.selectedAnnotations.first,
                      let featureAnnotation = selectedAnnotation as? MKMapFeatureAnnotation
                else { return }

                let request = MKMapItemRequest(mapFeatureAnnotation: featureAnnotation)
                request.getMapItem { mapItem, error in
                    guard error == nil else {
                        // self.displayError(error)
                        return
                    }
                    
                    if let mapItem {
                        // show detail view
                        self.context.selectedItem = mapItem
                        self.context.publish = true
                        
//                        self.context.pushDetail = true
//                        _ = NavigationLink("Detail", destination: MapDetails(mapItem: mapItem), isActive: self.context.$pushDetail)
                    }
                }
            }
        }

        /// - Tag: IconStyle
        private func setupPointOfInterestAnnotation(_ mapView: MKMapView, annotation: MKMapFeatureAnnotation) -> MKAnnotationView? {
            let markerAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
                                                                             for: annotation)
            if let markerAnnotationView = markerAnnotationView as? MKMarkerAnnotationView {
                
                markerAnnotationView.animatesWhenAdded = true
                
                /*
                 Tapping a point of interest automatically selects the annotation. Selected annotations automatically
                 show callouts when they're in an enabled state.
                 */
                markerAnnotationView.canShowCallout = true
                
                /*
                 When the user taps the detail disclosure button, use `mapView(_:annotationView:calloutAccessoryControlTapped:)`
                 to determine which annotation they tapped.
                 */
                let infoButton = UIButton(type: .detailDisclosure)
                markerAnnotationView.rightCalloutAccessoryView = infoButton
                
                /*
                 A feature annotation has properties that describe the type of the annotation, such as a point of interest.
                 A point of interest feature annotation also contains an icon style property, with icon and color information from
                 the tapped icon. Use these properties to customize the annotation, such as by changing icon colors based on the tapped annotation,
                 using the provided icon image, or picking an image based on the point-of-interest category.
                 */
                if let tappedFeatureColor = annotation.iconStyle?.backgroundColor,
                   let image = annotation.iconStyle?.image {
                    
                    markerAnnotationView.markerTintColor = tappedFeatureColor
                    infoButton.tintColor = tappedFeatureColor
                    
                    let imageView = UIImageView(image: image.withTintColor(tappedFeatureColor, renderingMode: .alwaysOriginal))
                    imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
                    markerAnnotationView.leftCalloutAccessoryView = imageView
                }
            }
            
            return markerAnnotationView
        }
    }
    
}

// MARK: - Previews

#if DEBUG
struct MapView_Previews: PreviewProvider {

    static var previews: some View {
        MapView()
    }

}
#endif

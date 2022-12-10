//
//  MapSearchView.swift
//  shaker
//
//  Created by Stan Miasnikov on 12/8/22.
//

import SwiftUI
import CoreLocation
import CoreLocationUI
import MapKit

struct MapSearchView: View {
    
    @State var searchRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    @State var currentPlacemark: CLPlacemark?
    @State private var places: [MKMapItem]?
    @State private var localSearch: MKLocalSearch? {
        willSet {
            // Clear the results and cancel the currently running local search before starting a new search.
            places = nil
            localSearch?.cancel()
        }
    }
    
    private var locationObservation: NSKeyValueObservation?
    
    /// - Parameter suggestedCompletion: A search completion that `MKLocalSearchCompleter` provides.
    ///     This view controller performs  a search with `MKLocalSearch.Request` using this suggested completion.
    private func search(for suggestedCompletion: MKLocalSearchCompletion)
    {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        search(using: searchRequest)
    }
    
    /// - Parameter queryString: A search string from the text the user enters into `UISearchBar`.
    private func search(for queryString: String?)
    {
        let searchRequest = MKLocalSearch.Request()
        // Only display results that are in travel-related categories.
        searchRequest.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.drinkPointsOfInterest)
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    private func distance(_ place: MKMapItem) -> Double
    {
        var distance: Double = 0.0
        if !place.isCurrentLocation, let currentLocation = LocationService.shared.currentLocation {
            distance = place.placemark.location?.distance(from: currentLocation) ?? 0.1
        }
        return distance
    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request)
    {
        // Confine the map search area to an area around the user's current location.
        searching = true
        searchRequest.region = searchRegion
        
        // Include only point-of-interest results. This excludes results based on address matches.
        searchRequest.resultTypes = .pointOfInterest
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [self] (response, error) in
            guard error == nil else {
                print("Error \(error?.localizedDescription ?? "")")
                return
            }
            
            self.searching = false
            
            if let pl = response?.mapItems {
                // sort places by distance
                self.places = pl.sorted(by: { first, second in
                    let d1 = self.distance(first)
                    let d2 = self.distance(second)
                    return d1 < d2
                })
            }
            else {
                self.places = nil
            }
        }
    }
    
    private enum Section: String, Identifiable, CaseIterable
    {
        case bars, restaurants, liquor_stores
        
        var displayName: String { rawValue.capitalized.replacingOccurrences(of: "_", with: " ") }
        
        var id: String { rawValue }
    }
    
    @State private var selectedSection = Section.bars
    @State private var currentSection = Section.bars
    @State private var searching = false

    var body: some View {
        VStack {
            Picker("Search for:", selection: $selectedSection) {
                ForEach(Section.allCases) { section in
                    Text(section.displayName)
                        .tag(section)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onReceive([self.selectedSection].publisher.first()) { (value) in
                if currentSection != selectedSection {
                    print(value.displayName)
                    search(for: value.displayName)
                    currentSection = selectedSection
                }
            }
            ZStack {
                if searching {
                    ProgressView()
                }
                List {
                    if searching {
                        HStack {
                            Text("Searching, please wait...")
                                .padding()
                            Spacer()
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                                .padding()
                        }
                    }
                    else {
                        if nil == places {
                            Text("Nothing has been found ")
                        }
                        else {
                            ForEach(places ?? [], id: \.self) { place in
                                NavigationLink {
                                    MapDetails(mapItem: place)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(place.name ?? "Unnamed location")
                                                .font(.headline)
                                                .clipped()
                                                .lineLimit(1)
                                            Text(place.placemark.formattedAddress ?? "")
                                                .font(.subheadline)
                                                .clipped()
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Text(String(format: "%.1fMi", self.distance(place)/Double.METERS_IN_MILE))
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                            .padding(.trailing, 3)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetListStyle())
            }
        }
        .onAppear() {
            LocationService.shared.requestLocation()
            let geocoder = CLGeocoder()
            // self.requestLocationUsage()
            if let currentLocation = LocationService.shared.currentLocation {
                geocoder.reverseGeocodeLocation(currentLocation) { [self] (placemark, error) in
                    guard error == nil else {
                        if let error = error as? NSError {
                            print("Reverse geocoding returned an error: \(error)")
                        }
                        return
                    }
                    
                    // Refine the search results by providing location information.
                    self.currentPlacemark = placemark?.first
                    self.searchRegion = MKCoordinateRegion(center: currentLocation.coordinate,
                                                           latitudinalMeters: 5.0 * Double.METERS_IN_MILE,
                                                           longitudinalMeters: 5.0 * Double.METERS_IN_MILE)
                    self.search(for: self.selectedSection.displayName)
                }
            }
        }
        .navigationTitle("\(self.selectedSection.displayName) Near Me")
    }
}

struct ActivityIndicator: UIViewRepresentable
{
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

struct MapSearchView_Previews: PreviewProvider {
    
    
    static var previews: some View {
        MapSearchView()
    }
}

import CoreLocation
import SwiftUI
import MapKit

struct LocationPicker: View {
    @Binding var coordinate: CLLocationCoordinate2D
    @Binding var radius: Double
    @State private var region: MKCoordinateRegion
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var showingSearchResults = false
    @State private var showingPermissionAlert = false
    
    private let minimumRadius: Double = 50
    private let maximumRadius: Double = 1000
    private let locationServices = LocationServices.shared
    
    init(coordinate: Binding<CLLocationCoordinate2D>, radius: Binding<Double>) {
        self._coordinate = coordinate
        self._radius = radius
        
        // Initialize region with the current coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        self._region = State(initialValue: MKCoordinateRegion(center: coordinate.wrappedValue, span: span))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Map view
            ZStack(alignment: .bottom) {
                MapView(region: $region, coordinate: $coordinate)
                    .edgesIgnoringSafeArea(.top)
                
                // Radius control
                radiusControl
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
            }
            
            // Search bar
            searchBar
                .padding()
                .background(Color(.systemBackground))
        }
        .overlay {
            if showingSearchResults {
                searchResultsList
                    .transition(.move(edge: .bottom))
            }
        }
        .overlay {
            if isSearching {
                ProgressView()
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
        }
        .alert("Location Access Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable location access in Settings to use this feature.")
        }
        .onAppear {
            checkLocationAuthorization()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search for a location", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                    showingSearchResults = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                requestCurrentLocation()
            }) {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var radiusControl: some View {
        VStack(spacing: 8) {
            Text("Radius: \(Int(radius))m")
                .font(.headline)
            
            HStack {
                Text("\(Int(minimumRadius))m")
                    .font(.caption)
                
                Slider(
                    value: $radius,
                    in: minimumRadius...maximumRadius,
                    step: 10
                )
                
                Text("\(Int(maximumRadius))m")
                    .font(.caption)
            }
        }
    }
    
    private var searchResultsList: some View {
        VStack {
            Spacer()
            
            List {
                ForEach(searchResults, id: \.self) { item in
                    Button(action: {
                        selectLocation(item)
                    }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown Location")
                                .font(.headline)
                            
                            if let address = item.placemark.formattedAddress {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(height: 300)
            .cornerRadius(12)
            .padding()
        }
        .background(
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    showingSearchResults = false
                }
        )
    }
    
    private func checkLocationAuthorization() {
        switch locationServices.locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = locationServices.locationManager.location {
                coordinate = location.coordinate
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        case .notDetermined:
            locationServices.locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func requestCurrentLocation() {
        locationServices.requestLocation { location in
            if let location = location {
                coordinate = location.coordinate
                region = MKCoordinateRegion(center: location.coordinate, span: region.span)
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        showingSearchResults = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        coordinate = item.placemark.coordinate
        region = MKCoordinateRegion(
            center: item.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        showingSearchResults = false
        searchText = item.name ?? ""
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.region = region
        
        // Add pin for selected location
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        // Add circle overlay for radius
        let circle = MKCircle(center: coordinate, radius: 100)
        mapView.addOverlay(circle)
        
        // Add gesture recognizer
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if it changed
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }
        
        // Update pin and circle if coordinate changed
        if let annotation = mapView.annotations.first as? MKPointAnnotation {
            annotation.coordinate = coordinate
        }
        
        // Remove old circle overlay and add new one
        mapView.removeOverlays(mapView.overlays)
        let circle = MKCircle(center: coordinate, radius: 100)
        mapView.addOverlay(circle)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
            if gestureRecognizer.state == .began {
                let mapView = gestureRecognizer.view as! MKMapView
                let point = gestureRecognizer.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                
                parent.coordinate = coordinate
            }
        }
    }
}

extension MKPlacemark {
    var formattedAddress: String? {
        guard let postalCode = postalCode else { return nil }
        
        var components = [String]()
        
        if let thoroughfare = thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = locality {
            components.append(locality)
        }
        
        if let administrativeArea = administrativeArea {
            components.append(administrativeArea)
        }
        
        components.append(postalCode)
        
        return components.joined(separator: ", ")
    }
} 
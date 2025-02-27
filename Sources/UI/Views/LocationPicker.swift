import SwiftUI
import MapKit
import CoreLocation

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
    
    init(coordinate: Binding<CLLocationCoordinate2D>, radius: Binding<Double>) {
        self._coordinate = coordinate
        self._radius = radius
        
        // Initialize region with the current coordinate
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        self._region = State(initialValue: MKCoordinateRegion(center: coordinate.wrappedValue, span: span))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
            
            // Map view
            ZStack {
                MapView(region: $region, coordinate: $coordinate, radius: radius)
                    .edgesIgnoringSafeArea(.all)
                
                // Center indicator
                Image(systemName: "mappin.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
                
                // Radius control
                VStack {
                    Spacer()
                    radiusControl
                }
                .padding()
            }
        }
        .onAppear {
            checkLocationAuthorization()
        }
        .sheet(isPresented: $showingSearchResults) {
            searchResultsList
        }
        .alert("Location Access Required", isPresented: $showingPermissionAlert) {
            Button("Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable location access in Settings to use this feature.")
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search location", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .onChange(of: searchText) { _ in
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                requestCurrentLocation()
            }) {
                Image(systemName: "location.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var radiusControl: some View {
        VStack(spacing: 8) {
            Text("Radius: \(Int(radius))m")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Slider(
                value: $radius,
                in: minimumRadius...maximumRadius,
                step: 50
            )
            .frame(maxWidth: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var searchResultsList: some View {
        NavigationView {
            List(searchResults, id: \.self) { item in
                Button(action: {
                    selectLocation(item)
                }) {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "Unknown location")
                            .font(.headline)
                        if let address = item.placemark.formattedAddress {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Search Results")
            .navigationBarItems(trailing: Button("Done") {
                showingSearchResults = false
            })
        }
    }
    
    private func checkLocationAuthorization() {
        switch services.locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = services.locationManager.currentLocation {
                region.center = location.coordinate
                coordinate = location.coordinate
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        case .notDetermined:
            services.locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    private func requestCurrentLocation() {
        services.locationManager.requestLocation()
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            
            if let error = error {
                services.logger.error("Location search failed: \(error.localizedDescription)", category: .system)
                return
            }
            
            searchResults = response?.mapItems ?? []
            if !searchResults.isEmpty {
                showingSearchResults = true
            }
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        coordinate = item.placemark.coordinate
        region.center = coordinate
        showingSearchResults = false
        searchText = ""
        searchResults = []
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var coordinate: CLLocationCoordinate2D
    let radius: Double
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.setRegion(region, animated: true)
        
        // Remove existing overlays and annotations
        view.removeOverlays(view.overlays)
        view.removeAnnotations(view.annotations.filter { !($0 is MKUserLocation) })
        
        // Add circle overlay for radius
        let circle = MKCircle(center: coordinate, radius: radius)
        view.addOverlay(circle)
        
        // Add pin annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        view.addAnnotation(annotation)
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
                renderer.fillColor = UIColor.accentColor.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.accentColor
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

extension MKPlacemark {
    var formattedAddress: String? {
        guard let subThoroughfare = subThoroughfare ?? thoroughfare,
              let locality = locality else { return nil }
        
        var components = [String]()
        
        if let thoroughfare = thoroughfare {
            components.append("\(subThoroughfare) \(thoroughfare)")
        }
        
        components.append(locality)
        
        if let administrativeArea = administrativeArea {
            components.append(administrativeArea)
        }
        
        return components.joined(separator: ", ")
    }
} 
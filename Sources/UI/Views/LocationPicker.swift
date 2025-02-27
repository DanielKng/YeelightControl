import SwiftUI
import MapKit
import CoreLocation

struct LocationPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLocation: Automation.Location?
    @StateObject private var locationManager = LocationManager()
    
    @State private var locationName = ""
    @State private var radius: Double = 100
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchResults: [MKMapItem] = []
    @State private var searchText = ""
    @State private var mapView: MKMapView?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(
                    text: $searchText,
                    placeholder: "Search location",
                    onSubmit: performSearch
                )
                .padding()
                
                // Search results
                if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { item in
                        Button {
                            selectLocation(item)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "")
                                    .font(.headline)
                                Text(item.placemark.title ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(height: 200)
                }
                
                // Map
                MapViewRepresentable(
                    region: $region,
                    selectedCoordinate: $selectedCoordinate,
                    radius: radius,
                    locationName: locationName,
                    onMapTap: handleMapTap
                )
                
                // Location details
                Form {
                    Section {
                        TextField("Location Name", text: $locationName)
                        
                        VStack(alignment: .leading) {
                            Text("Radius: \(Int(radius))m")
                            Slider(value: $radius, in: 50...500)
                        }
                    }
                }
                .frame(height: 150)
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let coordinate = selectedCoordinate {
                            selectedLocation = Automation.Location(
                                coordinate: coordinate,
                                radius: radius,
                                name: locationName
                            )
                            dismiss()
                        }
                    }
                    .disabled(locationName.isEmpty || selectedCoordinate == nil)
                }
            }
            .onAppear {
                if let location = locationManager.location {
                    region.center = location.coordinate
                }
            }
        }
    }
    
    private func handleMapTap(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        region.center = coordinate
        reverseGeocode(coordinate)
    }
    
    private func performSearch() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        MKLocalSearch(request: request).start { response, error in
            guard let response = response else { return }
            searchResults = response.mapItems
        }
    }
    
    private func selectLocation(_ item: MKMapItem) {
        locationName = item.name ?? ""
        selectedCoordinate = item.placemark.coordinate
        region.center = item.placemark.coordinate
        searchResults.removeAll()
        searchText = ""
    }
    
    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                locationName = placemark.name ?? placemark.locality ?? ""
            }
        }
    }
}

// MARK: - Map View Representable
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    let radius: Double
    let locationName: String
    let onMapTap: (CLLocationCoordinate2D) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        if let coordinate = selectedCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = locationName
            mapView.addAnnotation(annotation)
            
            let circle = MKCircle(center: coordinate, radius: radius)
            mapView.addOverlay(circle)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onMapTap(coordinate)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.systemRed
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "Location"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit(onSubmit)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
} 
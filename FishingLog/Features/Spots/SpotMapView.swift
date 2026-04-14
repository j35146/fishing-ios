import SwiftUI
import MapKit

struct SpotMapView: View {
    let spots: [Spot]
    let userLocation: CLLocationCoordinate2D?

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            // 用户位置
            UserAnnotation()

            // 钓点 Annotation
            ForEach(spots) { spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    SpotAnnotationView(spot: spot)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onAppear {
            if let loc = userLocation {
                position = .region(MKCoordinateRegion(
                    center: loc,
                    latitudinalMeters: 20000,
                    longitudinalMeters: 20000
                ))
            }
        }
    }
}

import Foundation
import MapKit
import Observation
import SwiftUI

@Observable
final class GlobeViewModel {
    var cameraPosition: MapCameraPosition = .automatic
    var selectedAnnotation: String?
    var visibleRegion: MKCoordinateRegion?

    func flyTo(coordinate: CLLocationCoordinate2D, altitude: Double = 500000) {
        withAnimation(.easeInOut(duration: 1.2)) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: coordinate,
                distance: altitude,
                heading: 0,
                pitch: 45
            ))
        }
    }

    func flyToRegion(_ region: RegionPreset) {
        withAnimation(.easeInOut(duration: 1.0)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: region.center,
                span: region.span
            ))
        }
    }

    func resetToGlobal() {
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                distance: 20000000,
                heading: 0,
                pitch: 0
            ))
        }
    }
}

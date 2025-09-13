import Foundation
import CoreLocation
struct Segment: Identifiable, Codable {
    let id: String
    let startNodeId: String
    let endNodeId: String
    let points: [Point]
    let distance: Double
    let elevationGain: Double
}

struct Point: Codable {
    let latitude: Double
    let longitude: Double
    let elevation: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

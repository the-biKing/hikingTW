import Foundation
import CoreLocation

struct Segment: Identifiable, Codable {
    let id: String
    let standardTime: Double
    let points: [Point]
}

struct Point: Codable, Hashable{
    let latitude: Double
    let longitude: Double
    let elevation: Double
}

struct SegmentCollection: Codable {
    let segments: [Segment]
}

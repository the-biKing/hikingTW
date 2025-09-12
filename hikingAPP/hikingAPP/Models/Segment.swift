import Foundation

struct Segment: Identifiable, Codable {
    let id: UUID
    let fromNodeID: UUID
    let toNodeID: UUID
    let shangheTimeMinutes: Double
    let distanceKm: Double?
    let elevationGainM: Double?
    let elevationLossM: Double?
    let isCustom: Bool
}

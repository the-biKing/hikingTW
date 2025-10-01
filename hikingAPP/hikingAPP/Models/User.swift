import Foundation

// MARK: - User struct
struct User: Codable {
    var id: UUID
    var username: String
    var speedFactor: Double
    var recentSpeedFactors: [Double]?
}

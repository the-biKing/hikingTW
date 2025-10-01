import Foundation
import CoreLocation

struct Node: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let nearBy: [String]

}


struct NodeCollection: Codable {
    let nodes: [Node]
}


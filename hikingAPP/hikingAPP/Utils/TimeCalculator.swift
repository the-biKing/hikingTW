import Foundation
import CoreLocation

struct TimeCalculator {
    
    // Helper to get standard time between two nodes based on segment direction
    static func standardTimeBetweenNodes(fromNodeID: String, toNodeID: String, segments: [Segment]) -> Double? {
        let forwardID = NavigationUtils.node2seg(fromNodeID, toNodeID)
        let reverseID = NavigationUtils.node2seg(toNodeID, fromNodeID)
        
        if let seg = segments.first(where: { $0.id == forwardID }) {
            return seg.standardTime
        } else if let seg = segments.first(where: { $0.id == reverseID }) {
            return seg.revStandardTime
        } else {
            return nil
        }
    }
}


import Foundation
import CoreLocation
import SwiftUI

/// Project a point onto a line segment AB
private func closestPointOnSegment(_ p: CLLocationCoordinate2D,
                                   _ a: CLLocationCoordinate2D,
                                   _ b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
    let ax = a.longitude, ay = a.latitude
    let bx = b.longitude, by = b.latitude
    let px = p.longitude, py = p.latitude

    let abx = bx - ax, aby = by - ay
    let apx = px - ax, apy = py - ay

    let ab2 = abx*abx + aby*aby
    let t = max(0, min(1, (ab2 > 0 ? (apx*abx + apy*aby) / ab2 : 0)))

    return CLLocationCoordinate2D(latitude: ay + t*aby,
                                  longitude: ax + t*abx)
}

private extension CLLocationCoordinate2D {
    func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}

struct NodeInfoPanel: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager

    var nextNodeName: String {
        switch navModel.planState {
        case .idle:
            return navModel.currentPlan.first ?? ""
        case .active, .offRoute:
            if let userLocation = locationManager.coordinate {
                let segments = loadSegments()
                if let closest = closestPointOnPlan(plan: navModel.currentPlan,
                                                    segments: segments,
                                                    user: userLocation) {
                    let plan = navModel.currentPlan
                    let nextIndex = closest.planIndex + 1
                    if nextIndex < plan.count {
                        return plan[nextIndex]
                    }
                }
            }
            return ""
        }
    }

    var prevNodeName: String {
        switch navModel.planState {
        case .idle:
            return ""
        case .active, .offRoute:
            if let userLocation = locationManager.coordinate {
                let segments = loadSegments()
                if let closest = closestPointOnPlan(plan: navModel.currentPlan,
                                                    segments: segments,
                                                    user: userLocation) {
                    let plan = navModel.currentPlan
                    let prevIndex = closest.planIndex
                    if prevIndex >= 0 && prevIndex < plan.count {
                        return plan[prevIndex]
                    }
                }
            }
            return ""
        }
    }

    var distance: String {
        switch navModel.planState {
        case .idle:
            if let userLocation = locationManager.coordinate,
               let firstNodeName = navModel.currentPlan.first {
                let nodes = loadNodes()
                if let node = nodes.first(where: { $0.id == firstNodeName }) {
                    let userCoord = CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let nodeCoord = CLLocationCoordinate2D(latitude: node.latitude, longitude: node.longitude)
                    let dist = userCoord.distance(from: nodeCoord)
                    return String(format: "%.0f", dist)
                }
            }
            return "0"
        case .active, .offRoute:
            if let userLocation = locationManager.coordinate {
                let segments = loadSegments()
                if let closest = closestPointOnPlan(plan: navModel.currentPlan,
                                                    segments: segments,
                                                    user: userLocation) {
                    return String(format: "%.0f", closest.distance)
                }
            }
            return "0"
        }
    }

    var elevation: String {
        switch navModel.planState {
        case .idle:
            return "N/A"
        case .active, .offRoute:
            if let userLocation = locationManager.coordinate {
                let segments = loadSegments()
                if let closest = closestPointOnPlan(plan: navModel.currentPlan,
                                                    segments: segments,
                                                    user: userLocation) {
                    return String(format: "%.0f", closest.point.elevation)
                }
            }
            return "0"
        }
    }

    var body: some View {
        Group {
            let segments = loadSegments()
            VStack(spacing: 8) {
                // Show plan state
                switch navModel.planState {
                case .idle:
                    Text("Idle").font(.caption).foregroundColor(.yellow)
                case .active:
                    Text("On Route").font(.caption).foregroundColor(.green)
                case .offRoute:
                    Text("Off Route").font(.caption).foregroundColor(.orange)
                }
                // Next Node capsule
                Text(nextNodeName)
                    .font(.caption)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.gray.opacity(0.2)))
                    .foregroundColor(.white)

                HStack(alignment: .center, spacing: 16) {
                    // Arrow
                    Image(systemName: "chevron.up")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .offset(x:5)

                    // Distance & Elevation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DIST: \(distance)")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("ELEV: \(elevation)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }

                // Previous Node capsule
                Text(prevNodeName)
                    .font(.caption)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.gray.opacity(0.2)))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
            .scaleEffect(1.5)
            .onAppear {
                if let userLocation = locationManager.coordinate {
                    let closest = closestPointOnPlan(plan: navModel.currentPlan,
                                                     segments: segments,
                                                     user: userLocation)
                    updatePlanState(distance: closest?.distance, navModel: navModel)
                } else {
                    navModel.planState = .idle
                }
            }
            .onReceive(locationManager.$coordinate) { _ in
                if let userLocation = locationManager.coordinate {
                    let closest = closestPointOnPlan(plan: navModel.currentPlan,
                                                     segments: segments,
                                                     user: userLocation)
                    updatePlanState(distance: closest?.distance, navModel: navModel)
                } else {
                    navModel.planState = .idle
                }
            }
        }
    }
}

// Helper: update navModel.planState based on distance + previous state
private func updatePlanState(distance: Double?, navModel: NavigationViewModel) {
    guard let d = distance else {
        navModel.planState = .idle
        return
    }
    switch navModel.planState {
    case .idle:
        if d <= 50 {
            navModel.planState = .active
        } else {
            navModel.planState = .idle
        }
    case .active:
        if d > 200 {
            navModel.planState = .offRoute
        } else {
            navModel.planState = .active
        }
    case .offRoute:
        if d > 1000 {
            navModel.planState = .idle
        } else {
            navModel.planState = .offRoute
        }
    }
}


struct TimeCalculator {
    static func estimatedTime(shangheMinutes: Double, factor: Double) -> Double {
        return shangheMinutes * factor
    }

    static func standardTime(actualMinutes: Double, factor: Double) -> Double {
        guard factor != 0 else { return actualMinutes }
        return actualMinutes / factor
    }
}

func extractRoutePoints(from segments: [Segment], plan: [String]) -> [Point] {
    guard plan.count >= 2 else { return [] }

    let segmentDict = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })

    var routePoints: [Point] = []

    for i in 0..<(plan.count - 1) {
        let nodeA = plan[i]
        let nodeB = plan[i + 1]
        let segId = node2seg(nodeA, nodeB)

        if let segment = segmentDict[segId] {
            // ✅ Just append all points every time
            routePoints.append(contentsOf: segment.points)
        } else {
            print("⚠️ Segment not found for ID: \(segId)")
        }
    }

    return routePoints
}

func loadSegments() -> [Segment] {
    guard let url = Bundle.main.url(forResource: "segments", withExtension: "json") else {
        print("❌ segments.json not found in bundle.")
        return []
    }

    do {
        let data = try Data(contentsOf: url)
        let segmentCollection = try JSONDecoder().decode(SegmentCollection.self, from: data)
        return segmentCollection.segments
    } catch {
        print("❌ Failed to decode segments.json: \(error)")
        return []
    }
}

func loadNodes() -> [Node] {
    guard let url = Bundle.main.url(forResource: "nodes", withExtension: "json") else {
        print("❌ Nodes.json not found in bundle.")
        return []
    }
    
    do {
        let data = try Data(contentsOf: url)
        let nodeCollection = try JSONDecoder().decode(NodeCollection.self, from: data)
        return nodeCollection.nodes
    } catch {
        print("❌ Failed to decode Nodes.json: \(error)")
        return []
    }
}

func node2seg(_ node1: String, _ node2: String) -> String {
    return "\(node1)_\(node2)"
}

/// Result of finding closest point along a plan
struct ClosestPointResult {
    let point: Point
    let segmentId: String
    let planIndex: Int
    let distance: Double
}


/// Find the closest point on the current plan, returning segment information
func closestPointOnPlan(plan: [String], segments: [Segment], user: CLLocationCoordinate2D) -> ClosestPointResult? {
    guard plan.count >= 2 else { return nil }

    let segmentDict = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })
    var bestResult: ClosestPointResult? = nil
    var bestDistance = Double.greatestFiniteMagnitude

    for i in 0..<(plan.count - 1) {
        let start = plan[i]
        let end = plan[i+1]
        let segId = node2seg(start, end)

        if let seg = segmentDict[segId] {
            for j in 0..<(seg.points.count - 1) {
                let a = CLLocationCoordinate2D(latitude: seg.points[j].latitude,
                                               longitude: seg.points[j].longitude)
                let b = CLLocationCoordinate2D(latitude: seg.points[j+1].latitude,
                                               longitude: seg.points[j+1].longitude)
                let candidate = closestPointOnSegment(user, a, b)
                let d = user.distance(from: candidate)
                if d < bestDistance {
                    bestDistance = d
                    // interpolate elevation
                    let elevA = seg.points[j].elevation
                    let elevB = seg.points[j+1].elevation

                    let ax = a.longitude, ay = a.latitude
                    let bx = b.longitude, by = b.latitude
                    let px = candidate.longitude, py = candidate.latitude

                    let abx = bx - ax, aby = by - ay
                    let apx = px - ax, apy = py - ay
                    let ab2 = abx*abx + aby*aby
                    let t = max(0, min(1, (ab2 > 0 ? (apx*abx + apy*aby) / ab2 : 0)))

                    let interpolatedElevation = elevA + (elevB - elevA) * t

                    let bestPoint = Point(latitude: candidate.latitude,
                                          longitude: candidate.longitude,
                                          elevation: interpolatedElevation)
                    bestResult = ClosestPointResult(point: bestPoint, segmentId: seg.id, planIndex: i, distance: d)
                }
            }
        }
    }

    return bestResult
}

#Preview {
    ZStack{
        Color.black
        NodeInfoPanel()
            .environmentObject(NavigationViewModel())
            .environmentObject(LocationManager())
        
    }
}

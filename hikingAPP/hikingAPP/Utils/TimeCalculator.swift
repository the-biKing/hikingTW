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

    // Helper to compute closest point info for the current state
    private func computeClosest() -> ClosestPointResult? {
        guard let userLocation = locationManager.coordinate else { return nil }
        let segments = loadSegments()
        return closestPointOnPlan(
            plan: navModel.currentPlan,
            segments: segments,
            user: userLocation,
            userLocations: locationManager.locationHistory + [userLocation]
        )
    }

    // Helper for next node name
    private func nextNodeName(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        switch navModel.planState {
        case .idle:
            return navModel.currentPlan.first ?? ""
        case .active, .offRoute:
            guard let closest = closest else { return "" }
            let plan = navModel.currentPlan
            let planIndex = closest.planIndex
            guard planIndex >= 0, planIndex + 1 < plan.count else { return "" }
            let nodes = loadNodes()
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex+1]
            let nodeA = nodes.first(where: { $0.id == nodeAName })
            let nodeB = nodes.first(where: { $0.id == nodeBName })
            guard let nodeACoord = nodeA.map({ CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }),
                  let nodeBCoord = nodeB.map({ CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }) else { return "" }
            // Determine stored segment direction (+1 for nodeA_nodeB, -1 for nodeB_nodeA)
            let segId = node2seg(nodeAName, nodeBName)
            let revSegId = node2seg(nodeBName, nodeAName)
            let segmentIds = segments.map { $0.id }
            let storedDirection: Int
            if segmentIds.contains(segId) {
                storedDirection = +1
            } else if segmentIds.contains(revSegId) {
                storedDirection = -1
            } else {
                storedDirection = +1 // fallback
            }
            let dir = detectDirection(
                userLocations: locationManager.locationHistory + (locationManager.coordinate.map { [$0] } ?? []),
                nodeA: nodeACoord,
                nodeB: nodeBCoord
            ) * storedDirection
            return dir == +1 ? plan[planIndex+1] : plan[planIndex]
        }
    }

    // Helper for previous node name
    private func prevNodeName(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        switch navModel.planState {
        case .idle:
            return ""
        case .active, .offRoute:
            guard let closest = closest else { return "" }
            let plan = navModel.currentPlan
            let planIndex = closest.planIndex
            guard planIndex >= 0, planIndex + 1 < plan.count else { return "" }
            let nodes = loadNodes()
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex+1]
            let nodeA = nodes.first(where: { $0.id == nodeAName })
            let nodeB = nodes.first(where: { $0.id == nodeBName })
            guard let nodeACoord = nodeA.map({ CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }),
                  let nodeBCoord = nodeB.map({ CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }) else { return "" }
            // Determine stored segment direction (+1 for nodeA_nodeB, -1 for nodeB_nodeA)
            let segId = node2seg(nodeAName, nodeBName)
            let revSegId = node2seg(nodeBName, nodeAName)
            let segmentIds = segments.map { $0.id }
            let storedDirection: Int
            if segmentIds.contains(segId) {
                storedDirection = +1
            } else if segmentIds.contains(revSegId) {
                storedDirection = -1
            } else {
                storedDirection = +1 // fallback
            }
            let dir = detectDirection(
                userLocations: locationManager.locationHistory + (locationManager.coordinate.map { [$0] } ?? []),
                nodeA: nodeACoord,
                nodeB: nodeBCoord
            ) * storedDirection
            return dir == +1 ? plan[planIndex] : plan[planIndex+1]
        }
    }

    // Helper for distance string
    private func distanceString(for closest: ClosestPointResult?, segments: [Segment]) -> String {
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
            return "N/A"
        case .offRoute:
            if let closest = closest {
                return String(format: "%.0f", closest.distance)
            }
            return "0"
        case .active:
            guard let closest = closest else { return "0" }
            let plan = navModel.currentPlan
            let planIndex = closest.planIndex
            guard planIndex >= 0, planIndex + 1 < plan.count else { return "0" }
            let nodes = loadNodes()
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex + 1]
            guard let nodeA = nodes.first(where: { $0.id == nodeAName }),
                  let nodeB = nodes.first(where: { $0.id == nodeBName }) else {
                return "0"
            }
            let nodeACoord = CLLocationCoordinate2D(latitude: nodeA.latitude, longitude: nodeA.longitude)
            let nodeBCoord = CLLocationCoordinate2D(latitude: nodeB.latitude, longitude: nodeB.longitude)
            let segId = node2seg(nodeAName, nodeBName)
            let revSegId = node2seg(nodeBName, nodeAName)
            let segmentIds = segments.map { $0.id }
            let storedDirection: Int
            if segmentIds.contains(segId) {
                storedDirection = +1
            } else if segmentIds.contains(revSegId) {
                storedDirection = -1
            } else {
                storedDirection = +1 // fallback
            }
            let direction = detectDirection(
                userLocations: locationManager.locationHistory + (locationManager.coordinate.map { [$0] } ?? []),
                nodeA: nodeACoord,
                nodeB: nodeBCoord
            ) * storedDirection
            let dist = distanceToNextNode(closest: closest, segments: segments, direction: direction)
            return String(format: "%.0f", dist)
        }
    }

    // Helper for elevation string
    private func elevationString(for closest: ClosestPointResult?) -> String {
        switch navModel.planState {
        case .idle:
            return "N/A"
        case .active, .offRoute:
            if let closest = closest {
                return String(format: "%.0f", closest.point.elevation)
            }
            return "0"
        }
    }

    var body: some View {
        Group {
            let closest = computeClosest()
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
                Text(nextNodeName(for: closest, segments: segments))
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
                        Text("DIST: \(distanceString(for: closest, segments: segments)) m")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("ELEV: \(elevationString(for: closest))")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }

                // Previous Node capsule
                Text(prevNodeName(for: closest, segments: segments))
                    .font(.caption)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.gray.opacity(0.2)))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
            .scaleEffect(1.5)
            .onAppear {
                let closest = computeClosest()
                updatePlanState(distance: closest?.distance, navModel: navModel)
            }
            .onReceive(locationManager.$coordinate) { _ in
                let closest = computeClosest()
                updatePlanState(distance: closest?.distance, navModel: navModel)
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
            let reverseSegId = node2seg(nodeB, nodeA)
            if let reverseSegment = segmentDict[reverseSegId] {
                // Append reversed points
                routePoints.append(contentsOf: reverseSegment.points.reversed())
            } else {
                print("⚠️ Segment not found for ID: \(segId)")
            }
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



/// Find the closest point on the current plan, returning segment information.
/// This version optionally accepts recent user locations (userLocations). If provided,
/// after a geometric nearest-point is found it will use the movement history (via
/// detectDirection) to disambiguate and (when appropriate) switch the returned
/// planIndex to the matching reversed plan index so the returned planIndex correctly
/// reflects the user's travel direction.
func closestPointOnPlan(
    plan: [String],
    segments: [Segment],
    user: CLLocationCoordinate2D,
    userLocations: [CLLocationCoordinate2D]? = nil
) -> ClosestPointResult? {
    guard plan.count >= 2 else { return nil }

    let segmentDict = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })
    var bestResult: ClosestPointResult? = nil
    var bestDistance = Double.greatestFiniteMagnitude

    // 1) Geometric search (same as before): check every plan edge (i -> i+1),
    // first try forward stored segment, then if missing try reversed stored segment.
    for i in 0..<(plan.count - 1) {
        let start = plan[i]
        let end = plan[i + 1]
        let segId = node2seg(start, end)
        let revSegId = node2seg(end, start)

        // forward stored segment
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

                    // interpolate elevation between seg.points[j] and seg.points[j+1]
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
            // prefer forward if available, continue to next plan index
            continue
        }

        // try stored reversed segment (end_start) and treat its points reversed
        if let revSeg = segmentDict[revSegId] {
            let pts = revSeg.points
            for j in 0..<(pts.count - 1) {
                // reverse the index mapping so this calculation is consistent with plan direction
                let a = CLLocationCoordinate2D(latitude: pts[pts.count - 1 - j].latitude,
                                               longitude: pts[pts.count - 1 - j].longitude)
                let b = CLLocationCoordinate2D(latitude: pts[pts.count - 2 - j].latitude,
                                               longitude: pts[pts.count - 2 - j].longitude)
                let candidate = closestPointOnSegment(user, a, b)
                let d = user.distance(from: candidate)
                if d < bestDistance {
                    bestDistance = d

                    let elevA = pts[pts.count - 1 - j].elevation
                    let elevB = pts[pts.count - 2 - j].elevation

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

                    // keep planIndex = i (because plan[i] -> plan[i+1] is the plan direction),
                    // but mark segmentId as the stored (reversed) id
                    bestResult = ClosestPointResult(point: bestPoint, segmentId: revSeg.id, planIndex: i, distance: d)
                }
            }
        }
    }

    // 2) If we have movement history, disambiguate the plan index when geometry alone is ambiguous.
    //    If detectDirection says the user is moving opposite relative to plan[i]->plan[i+1],
    //    try to find a matching reversed occurrence of that edge in the plan and return that index.
    if let currentBest = bestResult, let userLocs = userLocations, userLocs.count >= 2 {
        let idx = currentBest.planIndex
        if idx >= 0 && idx + 1 < plan.count {
            let nodeAName = plan[idx]
            let nodeBName = plan[idx + 1]

            // load node coordinates for direction detection
            let nodes = loadNodes()
            if let nodeA = nodes.first(where: { $0.id == nodeAName }),
               let nodeB = nodes.first(where: { $0.id == nodeBName }) {
                let nodeACoord = CLLocationCoordinate2D(latitude: nodeA.latitude, longitude: nodeA.longitude)
                let nodeBCoord = CLLocationCoordinate2D(latitude: nodeB.latitude, longitude: nodeB.longitude)

                let movementDir = detectDirection(userLocations: userLocs, nodeA: nodeACoord, nodeB: nodeBCoord)
                // movementDir == +1 means user moving from nodeA -> nodeB (plan direction),
                // movementDir == -1 means user moving from nodeB -> nodeA (opposite)
                if movementDir == -1 {
                    // find another index in the plan that represents nodeB -> nodeA (reverse occurrence)
                    if let revIndex = (0..<(plan.count - 1)).first(where: { plan[$0] == nodeBName && plan[$0 + 1] == nodeAName }) {
                        // if segment stored as nodeB_nodeA, prefer that segment and recompute a best candidate on it
                        let revSegId = node2seg(nodeBName, nodeAName)
                        if let revSeg = segmentDict[revSegId] {
                            var revBestPoint: Point? = nil
                            var revBestDistance = Double.greatestFiniteMagnitude
                            // compute closest point on the stored revSeg (no reversing here; revSeg stores B->A)
                            for j in 0..<(revSeg.points.count - 1) {
                                let a = CLLocationCoordinate2D(latitude: revSeg.points[j].latitude,
                                                               longitude: revSeg.points[j].longitude)
                                let b = CLLocationCoordinate2D(latitude: revSeg.points[j+1].latitude,
                                                               longitude: revSeg.points[j+1].longitude)
                                let candidate = closestPointOnSegment(user, a, b)
                                let d = user.distance(from: candidate)
                                if d < revBestDistance {
                                    revBestDistance = d

                                    let elevA = revSeg.points[j].elevation
                                    let elevB = revSeg.points[j+1].elevation

                                    let ax = a.longitude, ay = a.latitude
                                    let bx = b.longitude, by = b.latitude
                                    let px = candidate.longitude, py = candidate.latitude

                                    let abx = bx - ax, aby = by - ay
                                    let apx = px - ax, apy = py - ay
                                    let ab2 = abx*abx + aby*aby
                                    let t = max(0, min(1, (ab2 > 0 ? (apx*abx + apy*aby) / ab2 : 0)))

                                    let interpolatedElevation = elevA + (elevB - elevA) * t
                                    revBestPoint = Point(latitude: candidate.latitude,
                                                         longitude: candidate.longitude,
                                                         elevation: interpolatedElevation)
                                }
                            }
                            if let rbp = revBestPoint {
                                // return a ClosestPointResult that points at the reversed plan occurrence
                                return ClosestPointResult(point: rbp, segmentId: revSeg.id, planIndex: revIndex, distance: revBestDistance)
                            }
                        }
                    }
                }
            }
        }
    }

    return bestResult
}

/// Detect direction using the last N user locations to estimate movement
func detectDirection(
    userLocations: [CLLocationCoordinate2D],
    nodeA: CLLocationCoordinate2D,
    nodeB: CLLocationCoordinate2D
) -> Int {
    // Use last N points (e.g., 5)
    let N = 5
    let points = userLocations.suffix(N)
    guard points.count >= 2 else { return +1 }

    // Compute average movement vector
    var totalDx: Double = 0
    var totalDy: Double = 0
    var prev = points.first!
    for curr in points.dropFirst() {
        totalDx += curr.longitude - prev.longitude
        totalDy += curr.latitude - prev.latitude
        prev = curr
    }
    // If movement is too small, default to +1
    if abs(totalDx) < 1e-8 && abs(totalDy) < 1e-8 {
        return +1
    }

    // Segment vector
    let sx = nodeB.longitude - nodeA.longitude
    let sy = nodeB.latitude - nodeA.latitude

    // Dot product
    let dot = totalDx * sx + totalDy * sy

    return dot >= 0 ? +1 : -1
}

func distanceToNextNode(closest: ClosestPointResult, segments: [Segment], direction: Int) -> Double {
    guard let segment = segments.first(where: { $0.id == closest.segmentId }) else {
        return 0.0
    }

    // Find the index in segment.points closest to closest.point
    var closestIndex = 0
    var minDist = Double.greatestFiniteMagnitude
    for (index, point) in segment.points.enumerated() {
        let ptCoord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        let closestCoord = CLLocationCoordinate2D(latitude: closest.point.latitude,
                                                  longitude: closest.point.longitude)
        let dist = ptCoord.distance(from: closestCoord)
        if dist < minDist {
            minDist = dist
            closestIndex = index
        }
    }

    var totalDistance = 0.0

    if direction == +1 {
        // Sum distances from closestIndex to end
        for i in closestIndex..<(segment.points.count - 1) {
            let a = CLLocationCoordinate2D(latitude: segment.points[i].latitude, longitude: segment.points[i].longitude)
            let b = CLLocationCoordinate2D(latitude: segment.points[i+1].latitude, longitude: segment.points[i+1].longitude)
            totalDistance += a.distance(from: b)
        }
    } else {
        // Sum distances from closestIndex down to start
        if closestIndex > 0 {
            for i in stride(from: closestIndex, to: 0, by: -1) {
                let a = CLLocationCoordinate2D(latitude: segment.points[i].latitude, longitude: segment.points[i].longitude)
                let b = CLLocationCoordinate2D(latitude: segment.points[i-1].latitude, longitude: segment.points[i-1].longitude)
                totalDistance += a.distance(from: b)
            }
        }
    }

    return totalDistance
}

#Preview {
    ZStack{
        Color.black
        NodeInfoPanel()
            .environmentObject(NavigationViewModel())
            .environmentObject(LocationManager())
        
    }
}

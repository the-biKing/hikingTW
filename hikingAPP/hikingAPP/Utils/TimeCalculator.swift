import Foundation
import CoreLocation
import SwiftUI

/// Result of finding closest point along a plan
struct ClosestPointResult {
    let point: Point
    let segmentId: String
    let planIndex: Int
    let distance: Double
}


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

extension CLLocationCoordinate2D {
    func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}


// Helper: update navModel.planState based on distance + previous state
func updatePlanState(distance: Double?, navModel: NavigationViewModel) {
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

// MARK: - File helpers
func getUserFileURL() -> URL? {
    let fm = FileManager.default
    guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
        return nil
    }
    return docs.appendingPathComponent("user.json")
}

// MARK: - Save User
func saveUser(_ user: User) {
    guard let url = getUserFileURL() else { return }
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(user)
        try data.write(to: url)
        print("✅ User saved to JSON: \(url)")
    } catch {
        print("❌ Failed to save user: \(error)")
    }
}

// MARK: - Load User
func loadUser() -> User? {
    guard let url = getUserFileURL() else { return nil }
    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: data)
        return user
    } catch {
        print("❌ Failed to load user: \(error)")
        return nil
    }
}

// Helper to get standard time between two nodes based on segment direction
func standardTimeBetweenNodes(fromNodeID: String, toNodeID: String, segments: [Segment]) -> Double? {
    let forwardID = node2seg(fromNodeID, toNodeID)
    let reverseID = node2seg(toNodeID, fromNodeID)
    
    if let seg = segments.first(where: { $0.id == forwardID }) {
        return seg.standardTime
    } else if let seg = segments.first(where: { $0.id == reverseID }) {
        return seg.revStandardTime
    } else {
        return nil
    }
}

func closestNode(from userCoord: CLLocationCoordinate2D?, nodes: [Node]) -> ClosestNodeResult? {
    guard let userCoord = userCoord else { return nil }
    var best: ClosestNodeResult? = nil
    
    for node in nodes {
        let nodeCoord = CLLocationCoordinate2D(latitude: node.latitude, longitude: node.longitude)
        let d = userCoord.distance(from: nodeCoord)
        if best == nil || d < best!.distance {
            best = ClosestNodeResult(node: node, distance: d)
        }
    }
    return best
}


/// Find the closest point on the current plan, returning segment information.
/// This version optionally accepts recent user locations (userLocations). If provided,
/// after a geometric nearest-point is found it will use the movement history (via
/// detectDirection) to disambiguate and (when appropriate) switch the returned
/// planIndex to the matching reversed plan index so the returned planIndex correctly
/// reflects the user's travel direction.
// Helper function to evaluate a candidate segment (forward or reversed) and find the closest point.
private func evaluateCandidateSegment(
    user: CLLocationCoordinate2D,
    segment: Segment,
    planIndex: Int,
    segmentId: String,
    reversed: Bool = false
) -> ClosestPointResult? {
    var bestDistance = Double.greatestFiniteMagnitude
    var bestPoint: Point? = nil
    let pts = segment.points
    let count = pts.count
    if count < 2 {
        return nil
    }
    for j in 0..<(count - 1) {
        let (aPt, bPt, elevA, elevB): (Point, Point, Double, Double)
        if reversed {
            aPt = pts[count - 1 - j]
            bPt = pts[count - 2 - j]
            elevA = aPt.elevation
            elevB = bPt.elevation
        } else {
            aPt = pts[j]
            bPt = pts[j+1]
            elevA = aPt.elevation
            elevB = bPt.elevation
        }
        let a = CLLocationCoordinate2D(latitude: aPt.latitude, longitude: aPt.longitude)
        let b = CLLocationCoordinate2D(latitude: bPt.latitude, longitude: bPt.longitude)
        let candidate = closestPointOnSegment(user, a, b)
        let d = user.distance(from: candidate)
        if d < bestDistance {
            bestDistance = d
            // Interpolate elevation
            let ax = a.longitude, ay = a.latitude
            let bx = b.longitude, by = b.latitude
            let px = candidate.longitude, py = candidate.latitude
            let abx = bx - ax, aby = by - ay
            let apx = px - ax, apy = py - ay
            let ab2 = abx*abx + aby*aby
            let t = max(0, min(1, (ab2 > 0 ? (apx*abx + apy*aby) / ab2 : 0)))
            let interpolatedElevation = elevA + (elevB - elevA) * t
            bestPoint = Point(latitude: candidate.latitude, longitude: candidate.longitude, elevation: interpolatedElevation)
        }
    }
    if let bp = bestPoint {
        return ClosestPointResult(point: bp, segmentId: segmentId, planIndex: planIndex, distance: bestDistance)
    } else {
        return nil
    }
}

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

    // 1) Geometric search: check every plan edge (i -> i+1), try forward then reversed segment.
    for i in 0..<(plan.count - 1) {
        let start = plan[i]
        let end = plan[i + 1]
        let segId = node2seg(start, end)
        let revSegId = node2seg(end, start)

        // Try forward stored segment
        if let seg = segmentDict[segId] {
            if let result = evaluateCandidateSegment(user: user, segment: seg, planIndex: i, segmentId: seg.id, reversed: false) {
                if result.distance < bestDistance {
                    bestDistance = result.distance
                    bestResult = result
                }
            }
            // Prefer forward if available, continue to next plan index
            continue
        }
        // Try stored reversed segment (end_start) and treat its points reversed
        if let revSeg = segmentDict[revSegId] {
            if let result = evaluateCandidateSegment(user: user, segment: revSeg, planIndex: i, segmentId: revSeg.id, reversed: true) {
                if result.distance < bestDistance {
                    bestDistance = result.distance
                    bestResult = result
                }
            }
        }
    }

    // 2) If we have movement history, disambiguate the plan index when geometry alone is ambiguous.
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
                            if let revResult = evaluateCandidateSegment(user: user, segment: revSeg, planIndex: revIndex, segmentId: revSeg.id, reversed: false) {
                                return revResult
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

private func findClosestPointIndex(segment: Segment, to point: Point) -> Int {
    var closestIndex = 0
    var minDist = Double.greatestFiniteMagnitude
    let targetCoord = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
    for (index, pt) in segment.points.enumerated() {
        let ptCoord = CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude)
        let dist = ptCoord.distance(from: targetCoord)
        if dist < minDist {
            minDist = dist
            closestIndex = index
        }
    }
    return closestIndex
}

func distanceToNextNode(closest: ClosestPointResult, segments: [Segment], direction: Int) -> Double {
    guard let segment = segments.first(where: { $0.id == closest.segmentId }) else {
        return 0.0
    }

    let closestIndex = findClosestPointIndex(segment: segment, to: closest.point)

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


// Returns the total elevation gain (if positive) or -loss (if negative) to the next node
func elevationChangeToNextNode(closest: ClosestPointResult, segments: [Segment], direction: Int) -> Double {
    guard let segment = segments.first(where: { $0.id == closest.segmentId }) else {
        return 0.0
    }

    let closestIndex = findClosestPointIndex(segment: segment, to: closest.point)

    var gain: Double = 0.0
    var loss: Double = 0.0

    if direction == +1 {
        // Sum elevation differences from closestIndex to end
        for i in closestIndex..<(segment.points.count - 1) {
            let elevA = segment.points[i].elevation
            let elevB = segment.points[i+1].elevation
            let diff = elevB - elevA
            if diff > 0 {
                gain += diff
            } else {
                loss += -diff
            }
        }
    } else {
        // Sum elevation differences from closestIndex down to start
        if closestIndex > 0 {
            for i in stride(from: closestIndex, to: 0, by: -1) {
                let elevA = segment.points[i].elevation
                let elevB = segment.points[i-1].elevation
                let diff = elevB - elevA
                if diff > 0 {
                    gain += diff
                } else {
                    loss += -diff
                }
            }
        }
    }

    // If loss is greater, return -loss; otherwise return gain
    if loss > gain {
        return -loss
    } else {
        return gain
    }
}

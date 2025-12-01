import Foundation
import CoreLocation
import SwiftUI
import UserNotifications

let offrouteThreshold: Double = 50

/// Result of finding closest point along a plan
struct ClosestPointResult {
    let point: Point
    let validSegmentID: String
    let userDirection: Int
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
        if d <= offrouteThreshold {
            navModel.planState = .active
        } else {
            navModel.planState = .idle
        }
    case .active:
        if d > offrouteThreshold {//testing
            navModel.planState = .offRoute
            sendOffRouteNotification()
        } else {
            navModel.planState = .active
        }
    case .offRoute:
        if d < offrouteThreshold{
            navModel.planState = .active
        } else if d > 1000 {
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

func sendOffRouteNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Warning"
    content.body = "You have gone off route!"
    content.sound = .default
    
    // Trigger immediately
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    
    let request = UNNotificationRequest(identifier: UUID().uuidString,
                                        content: content,
                                        trigger: trigger)
    
    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Notification error: \(error)")
        }
    }
}

func loadSegments() -> [Segment] {
    // Redirect to manager to return whatever is currently loaded in memory
    return SegmentDataManager.shared.getAllLoadedSegments()
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
        // Always return the segmentId passed in (which must be plan direction nodeA_nodeB)
        return ClosestPointResult(point: bp, validSegmentID: segmentId, userDirection: +1, planIndex: planIndex, distance: bestDistance)
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

    // Purely geometric: check every plan edge (i -> i+1), always use plan direction as segmentId
    for i in 0..<(plan.count - 1) {
        let start = plan[i]
        let end = plan[i + 1]
        let planSegId = node2seg(start, end)
        let revSegId = node2seg(end, start)

        if let seg = segmentDict[planSegId] {
            // Stored in plan direction
            if let result = evaluateCandidateSegment(user: user, segment: seg, planIndex: i, segmentId: planSegId, reversed: false) {
                if result.distance < bestDistance {
                    bestDistance = result.distance
                    // Insert userDirection: +1 for forward
                    bestResult = ClosestPointResult(point: result.point, validSegmentID: result.validSegmentID, userDirection: +1, planIndex: result.planIndex, distance: result.distance)
                }
            }
            continue
        }
        if let revSeg = segmentDict[revSegId] {
            // Stored in reverse, but still return planSegId
            if let result = evaluateCandidateSegment(user: user, segment: revSeg, planIndex: i, segmentId: planSegId, reversed: true) {
                if result.distance < bestDistance {
                    bestDistance = result.distance
                    // Insert userDirection: +1 for forward (since planSegId is still forward)
                    bestResult = ClosestPointResult(point: result.point, validSegmentID: result.validSegmentID, userDirection: +1, planIndex: result.planIndex, distance: result.distance)
                }
            }
        }
    }

    // Inserted logic: check for both directions and handle direction flipping if needed
    if var bestResult = bestResult {
        let planIndex = bestResult.planIndex
        if planIndex >= 0 && planIndex < plan.count - 1 {
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex + 1]

            // Check if both nodeA -> nodeB and nodeB -> nodeA exist in the plan
            var hasForward = false
            var hasReverse = false
            for i in 0..<(plan.count - 1) {
                if plan[i] == nodeAName && plan[i+1] == nodeBName {
                    hasForward = true
                }
                if plan[i] == nodeBName && plan[i+1] == nodeAName {
                    hasReverse = true
                }
            }
            if hasForward && hasReverse {
                if let userLocations = userLocations {
                    let direction = detectDirection(nodeAID: nodeAName, nodeBID: nodeBName, userLocations: userLocations, segments: segments)
                    if direction == -1 {
                        // Find reversed plan index
                        var reversedIndex: Int? = nil
                        for i in 0..<(plan.count - 1) {
                            if plan[i] == nodeBName && plan[i+1] == nodeAName {
                                reversedIndex = i
                                break
                            }
                        }
                        if let reversedIndex = reversedIndex {
                            bestResult = ClosestPointResult(
                                point: bestResult.point,
                                validSegmentID: node2seg(nodeBName, nodeAName),
                                userDirection: -1,
                                planIndex: reversedIndex,
                                distance: bestResult.distance
                            )
                        }
                    }
                }
            }
        }
        return bestResult
    }
    return bestResult
}



/// Detect direction using userLocations and segment points index-trend logic
func detectDirection(
    nodeAID: String,
    nodeBID: String,
    userLocations: [CLLocationCoordinate2D],
    segments: [Segment]
) -> Int {

    // 1. Locate the correct segment for A→B or B→A
    let forwardID = node2seg(nodeAID, nodeBID)
    let reverseID = node2seg(nodeBID, nodeAID)

    guard let segment = segments.first(where: { $0.id == forwardID || $0.id == reverseID }) else {
        return +1
    }

    // 2. Normalize points so array is always ordered A→B
    let points: [Point]
    if segment.id == forwardID {
        points = segment.points
    } else {
        points = segment.points.reversed()
    }

    // 3. Build index list by finding nearest segment point to each user location
    var indexList: [Int] = []
    indexList.reserveCapacity(userLocations.count)

    for loc in userLocations {
        var bestIndex = 0
        var bestDist = Double.greatestFiniteMagnitude
        let locCoord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)

        for (i, pt) in points.enumerated() {
            let ptCoord = CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude)
            let d = locCoord.distance(from: ptCoord)
            if d < bestDist {
                bestDist = d
                bestIndex = i
            }
        }

        indexList.append(bestIndex)
    }

    // 4. If too few samples, default direction is +1
    if indexList.count < 2 { return +1 }

    // 5. Compute trend of indices
    let first = indexList.first!
    let last = indexList.last!

    if last > first { return +1 }     // moving A→B
    if last < first { return -1 }     // moving B→A (reverse)
    return +1                         // no change: assume forward
}


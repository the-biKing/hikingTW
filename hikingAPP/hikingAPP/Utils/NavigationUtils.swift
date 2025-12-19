import Foundation
import CoreLocation

struct ClosestPointResult {
    let point: Point
    let validSegmentID: String
    let userDirection: Int
    let planIndex: Int
    let distance: Double
}

struct ClosestNodeResult {
    let node: Node
    let distance: Double
}

struct CurrentSegmentResult {
    let segment: Segment
    let points: [Point]
    let planIndex: Int
    let closestIndex: Int
}

struct NavigationUtils {
    
    static let offrouteThreshold: Double = 50

    static func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let lon2 = to.longitude * .pi / 180
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Project a point onto a line segment AB
    static func closestPointOnSegment(_ p: CLLocationCoordinate2D,
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

    // Helper: update navModel.planState based on distance + previous state
    static func updatePlanState(distance: Double?, navModel: NavigationViewModel) {
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
            if d > offrouteThreshold {
                navModel.planState = .offRoute
                NotificationManager.shared.sendOffRouteNotification()
            } else {
                navModel.planState = .active
            }
        case .offRoute:
            if d < offrouteThreshold {
                navModel.planState = .active
            } else if d > 1000 {
                navModel.planState = .idle
            } else {
                navModel.planState = .offRoute
            }
        }
    }

    static func extractRoutePoints(from segments: [Segment], plan: [String]) -> [Point] {
        guard plan.count >= 2 else { return [] }

        let segmentDict = Dictionary(uniqueKeysWithValues: segments.map { ($0.id, $0) })
        var routePoints: [Point] = []

        for i in 0..<(plan.count - 1) {
            let nodeA = plan[i]
            let nodeB = plan[i + 1]
            let segId = node2seg(nodeA, nodeB)

            if let segment = segmentDict[segId] {
                routePoints.append(contentsOf: segment.points)
            } else {
                let reverseSegId = node2seg(nodeB, nodeA)
                if let reverseSegment = segmentDict[reverseSegId] {
                    routePoints.append(contentsOf: reverseSegment.points.reversed())
                } else {
                    print("⚠️ Segment not found for ID: \(segId)")
                }
            }
        }
        return routePoints
    }

    static func node2seg(_ node1: String, _ node2: String) -> String {
        return "\(node1)_\(node2)"
    }

    static func closestNode(from userCoord: CLLocationCoordinate2D?, nodes: [Node]) -> ClosestNodeResult? {
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

    static func closestPointOnPlan(
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
                if let result = evaluateCandidateSegment(user: user, segment: seg, planIndex: i, segmentId: planSegId, reversed: false) {
                    if result.distance < bestDistance {
                        bestDistance = result.distance
                        bestResult = ClosestPointResult(point: result.point, validSegmentID: result.validSegmentID, userDirection: +1, planIndex: result.planIndex, distance: result.distance)
                    }
                }
                continue
            }
            if let revSeg = segmentDict[revSegId] {
                if let result = evaluateCandidateSegment(user: user, segment: revSeg, planIndex: i, segmentId: planSegId, reversed: true) {
                    if result.distance < bestDistance {
                        bestDistance = result.distance
                        bestResult = ClosestPointResult(point: result.point, validSegmentID: result.validSegmentID, userDirection: +1, planIndex: result.planIndex, distance: result.distance)
                    }
                }
            }
        }

        if var bestResult = bestResult {
            let planIndex = bestResult.planIndex
            if planIndex >= 0 && planIndex < plan.count - 1 {
                let nodeAName = plan[planIndex]
                let nodeBName = plan[planIndex + 1]

                var hasForward = false
                var hasReverse = false
                for i in 0..<(plan.count - 1) {
                    if plan[i] == nodeAName && plan[i+1] == nodeBName { hasForward = true }
                    if plan[i] == nodeBName && plan[i+1] == nodeAName { hasReverse = true }
                }
                if hasForward && hasReverse {
                    if let userLocations = userLocations {
                        let direction = detectDirection(nodeAID: nodeAName, nodeBID: nodeBName, userLocations: userLocations, segments: segments)
                        if direction == -1 {
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

    private static func evaluateCandidateSegment(
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
        if count < 2 { return nil }
        
        for j in 0..<(count - 1) {
            let (aPt, bPt, elevA, elevB): (Point, Point, Double, Double)
            if reversed {
                aPt = pts[count - 1 - j]
                bPt = pts[count - 2 - j]
            } else {
                aPt = pts[j]
                bPt = pts[j+1]
            }
            elevA = aPt.elevation
            elevB = bPt.elevation
            
            let a = CLLocationCoordinate2D(latitude: aPt.latitude, longitude: aPt.longitude)
            let b = CLLocationCoordinate2D(latitude: bPt.latitude, longitude: bPt.longitude)
            let candidate = closestPointOnSegment(user, a, b)
            let d = user.distance(from: candidate)
            if d < bestDistance {
                bestDistance = d
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
            return ClosestPointResult(point: bp, validSegmentID: segmentId, userDirection: +1, planIndex: planIndex, distance: bestDistance)
        } else {
            return nil
        }
    }

    static func detectDirection(
        nodeAID: String,
        nodeBID: String,
        userLocations: [CLLocationCoordinate2D],
        segments: [Segment]
    ) -> Int {
        let forwardID = node2seg(nodeAID, nodeBID)
        let reverseID = node2seg(nodeBID, nodeAID)

        guard let segment = segments.first(where: { $0.id == forwardID || $0.id == reverseID }) else {
            return +1
        }

        let points: [Point] = (segment.id == forwardID) ? segment.points : segment.points.reversed()

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

        if indexList.count < 2 { return +1 }

        let first = indexList.first!
        let last = indexList.last!

        if last > first { return +1 }
        if last < first { return -1 }
        return +1
    }

    static func totalSegmentDistance(from fromID: String, to toID: String, segments: [Segment]) -> Double {
        let segId = node2seg(fromID, toID)
        let revSegId = node2seg(toID, fromID)
        if let seg = segments.first(where: { $0.id == segId || $0.id == revSegId }) {
            var total = 0.0
            for i in 0..<(seg.points.count - 1) {
                let a = CLLocationCoordinate2D(latitude: seg.points[i].latitude, longitude: seg.points[i].longitude)
                let b = CLLocationCoordinate2D(latitude: seg.points[i+1].latitude, longitude: seg.points[i+1].longitude)
                total += a.distance(from: b)
            }
            return total
        }
        return 1.0 // prevent divide-by-zero
    }

    static func findClosestPointIndex(points: [Point], to point: Point) -> Int {
        var bestIndex = 0
        var bestDist = Double.greatestFiniteMagnitude
        let target = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        for (i, pt) in points.enumerated() {
            let ptCoord = CLLocationCoordinate2D(latitude: pt.latitude, longitude: pt.longitude)
            let d = target.distance(from: ptCoord)
            if d < bestDist {
                bestDist = d
                bestIndex = i
            }
        }
        return bestIndex
    }

    static func distChangetoNextNode(current: CurrentSegmentResult) -> Double {
        let points = current.points
        let idx = current.closestIndex
        guard idx < points.count - 1 else { return 0.0 }

        var total: Double = 0.0
        for i in idx..<(points.count - 1) {
            let a = CLLocationCoordinate2D(latitude: points[i].latitude, longitude: points[i].longitude)
            let b = CLLocationCoordinate2D(latitude: points[i+1].latitude, longitude: points[i+1].longitude)
            total += a.distance(from: b)
        }
        return total
    }

    static func elevChangetoNextNode(current: CurrentSegmentResult) -> Double {
        let points = current.points
        let idx = current.closestIndex
        guard idx < points.count - 1 else { return 0.0 }

        var gain: Double = 0.0
        var loss: Double = 0.0

        for i in idx..<(points.count - 1) {
            let diff = points[i+1].elevation - points[i].elevation
            if diff > 0 { gain += diff }
            else { loss += -diff }
        }
        return (loss > gain) ? -loss : gain
    }
}

extension CLLocationCoordinate2D {
    func distance(from other: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}

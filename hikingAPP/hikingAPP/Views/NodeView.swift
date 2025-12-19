import Foundation
import CoreLocation
import SwiftUI

struct NodeInfoPanel: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager

    // Helper to compute closest point info for the current state
    private func computeClosest(for segments: [Segment]) -> ClosestPointResult? {
        guard let userLocation = locationManager.coordinate else { return nil }
        return NavigationUtils.closestPointOnPlan(
            plan: navModel.currentPlan,
            segments: segments,
            user: userLocation,
            userLocations: locationManager.locationHistory + [userLocation]
        )
    }
     
    // Helper: compute the current segment in user's travel direction
    private func computeCurrentSegment(for closest: ClosestPointResult?, segments: [Segment]) -> CurrentSegmentResult? {
        guard let closest = closest else { return nil }
        guard let seg = segments.first(where: { $0.id == closest.validSegmentID }) else { return nil }
        // order points so they are in the user's travel direction
        let orderedPoints = (closest.userDirection == +1)
            ? seg.points
            : Array(seg.points.reversed())

        // Compute index AFTER ordering
        let closestIdx = NavigationUtils.findClosestPointIndex(points: orderedPoints, to: closest.point)

        return CurrentSegmentResult(
            segment: seg,
            points: orderedPoints,
            planIndex: closest.planIndex,
            closestIndex: closestIdx
        )
    }

    // Helper for next node name
    private func nextNodeName(for closest: ClosestPointResult?, nodes: [Node]) -> String {
        switch navModel.planState {
        case .idle:
            return nodes.first(where: { $0.id == navModel.currentPlan.first })?.name ?? ""
        case .active, .offRoute:
            guard let closest,
                  closest.planIndex + 1 < navModel.currentPlan.count
            else { return "" }

            let nextID = navModel.currentPlan[closest.planIndex + 1]
            return nodes.first(where: { $0.id == nextID })?.name ?? nextID
        }
    }
    
    // Helper for previous node name
    private func prevNodeName(for closest: ClosestPointResult?, nodes: [Node]) -> String {
        switch navModel.planState {
        case .idle: return ""
        case .active, .offRoute:
            guard let closest,
                  closest.planIndex < navModel.currentPlan.count
            else { return "" }

            let prevID = navModel.currentPlan[closest.planIndex]
            return nodes.first(where: { $0.id == prevID })?.name ?? prevID
        }
    }
    
    // Helper for distance string
    private func distanceString(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        switch navModel.planState {
        case .idle:
            if let userLocation = locationManager.coordinate,
               let firstNodeName = navModel.currentPlan.first {
                let nodes = PersistenceManager.shared.loadNodes()
                if let node = nodes.first(where: { $0.id == firstNodeName }) {
                    let userCoord = CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let nodeCoord = CLLocationCoordinate2D(latitude: node.latitude, longitude: node.longitude)
                    let dist = userCoord.distance(from: nodeCoord)
                    return String(format: "%.0f", dist)
                }
                return "node N/A"
            }
            return "N/A"
        case .offRoute:
            if let closest = closest {
                return String(format: "%.0f", closest.distance)
            }
            return "0"
        case .active:
            if let closest = closest, let current = computeCurrentSegment(for: closest, segments: segments) {
                let dist = NavigationUtils.distChangetoNextNode(current: current)
                return String(format: "%.0f", dist)
            }
            return "0"
        }
    }
    
    // Helper for elevation string
    private func elevationString(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        switch navModel.planState {
        case .idle:
            return "N/A"
        case .offRoute:
            if let closest = closest {
                return String(format: "%.0f", closest.point.elevation)
            }
            return "0"
        case .active:
            if let closest = closest, let current = computeCurrentSegment(for: closest, segments: segments) {
                let elevChange = NavigationUtils.elevChangetoNextNode(current: current)
                return String(format: "%.0f", elevChange)
            }
            return "0"
        }
    }
    
    var body: some View {
        Group {
            let segments = SegmentDataManager.shared.getAllLoadedSegments()
            let nodes = PersistenceManager.shared.loadNodes()
            let closest = computeClosest(for: segments)
            
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
                
                NavigationLink(destination:
                                PlanDisplayView(
                                    navModel: navModel,
                                    title: navModel.currentPlan.isEmpty ? "目前沒有計劃" : "目前路線",
                                    route: navModel.currentPlan,
                                    nodes: nodes
                                )
                ) {
                    Text(nextNodeName(for: closest, nodes: nodes))
                        .font(.caption)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppColors.surface))
                        .foregroundColor(AppColors.text)
                }.simultaneousGesture(TapGesture().onEnded {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                })
                
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "chevron.up")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                        .offset(x: 5)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DIST: \(distanceString(for: closest, segments: segments)) m")
                            .font(.caption)
                            .foregroundColor(AppColors.text)
                        Text("ELEV: \(elevationString(for: closest, segments: segments)) m")
                            .font(.caption)
                            .foregroundColor(AppColors.text)
                    }
                }
                
                NavigationLink(destination:
                                PlanDisplayView(
                                    navModel: navModel,
                                    title: navModel.currentPlan.isEmpty ? "目前沒有計劃" : "目前路線",
                                    route: navModel.currentPlan,
                                    nodes: nodes
                                )
                ) {
                    Text(prevNodeName(for: closest, nodes: nodes))
                        .font(.caption)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppColors.surface))
                        .foregroundColor(AppColors.text)
                }.simultaneousGesture(TapGesture().onEnded {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                })
            }
            .padding(.bottom, 20)
            .scaleEffect(1.5)
            .onAppear {
                NavigationUtils.updatePlanState(distance: closest?.distance, navModel: navModel)
                if let closest = closest,
                   closest.planIndex + 1 < navModel.currentPlan.count {
                    navModel.nextNodeID = navModel.currentPlan[closest.planIndex + 1]
                    navModel.prevNodeID = navModel.currentPlan[closest.planIndex]
                    navModel.planIndex = closest.planIndex
                    UserDefaults.standard.set(closest.planIndex, forKey: "CurrentPlanIndex")
                }
                if navModel.planState == .active, let closest = closest, let current = computeCurrentSegment(for: closest, segments: segments) {
                    let remaining = NavigationUtils.distChangetoNextNode(current: current)
                    navModel.segmentDistanceLeft = remaining
                }
            }
            .onReceive(locationManager.$coordinate) { _ in
                NavigationUtils.updatePlanState(distance: closest?.distance, navModel: navModel)
                if let closest = closest,
                   closest.planIndex + 1 < navModel.currentPlan.count {
                    navModel.nextNodeID = navModel.currentPlan[closest.planIndex + 1]
                    navModel.prevNodeID = navModel.currentPlan[closest.planIndex]
                    navModel.planIndex = closest.planIndex
                    UserDefaults.standard.set(closest.planIndex, forKey: "CurrentPlanIndex")
                }
                if navModel.planState == .active, let closest = closest, let current = computeCurrentSegment(for: closest, segments: segments) {
                    let remaining = NavigationUtils.distChangetoNextNode(current: current)
                    navModel.segmentDistanceLeft = remaining
                }
            }
        }
    }
}



//
//  NodeView.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/10/2.
//
import Foundation
import CoreLocation
import SwiftUI

struct NodeInfoPanel: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager

    private func computeSegmentDirection(nodeAName: String, nodeBName: String, segments: [Segment]) -> Int {
        let segId = node2seg(nodeAName, nodeBName)
        let revSegId = node2seg(nodeBName, nodeAName)
        let segmentIds = segments.map { $0.id }
        let storedDirection: Int
        if segmentIds.contains(segId) { storedDirection = +1 }
        else if segmentIds.contains(revSegId) { storedDirection = -1 }
        else { storedDirection = +1 }
        
        guard let nodeA = loadNodes().first(where: { $0.id == nodeAName }),
              let nodeB = loadNodes().first(where: { $0.id == nodeBName }) else { return storedDirection }

        let userLocs = locationManager.locationHistory + (locationManager.coordinate.map { [$0] } ?? [])
        return detectDirection(userLocations: userLocs,
                               nodeA: CLLocationCoordinate2D(latitude: nodeA.latitude, longitude: nodeA.longitude),
                               nodeB: CLLocationCoordinate2D(latitude: nodeB.latitude, longitude: nodeB.longitude)) * storedDirection
    }

    // Helper to compute closest point info for the current state
    private func computeClosest(for segments : [Segment]) -> ClosestPointResult? {
        guard let userLocation = locationManager.coordinate else { return nil }
        return closestPointOnPlan(
            plan: navModel.currentPlan,
            segments: segments,
            user: userLocation,
            userLocations: locationManager.locationHistory + [userLocation]
        )
    }

    // Helper for next node name
    private func nextNodeName(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        let nextId = computeNextNodeID(for: closest, segments: segments)
        guard !nextId.isEmpty else { return "" }
        if let node = loadNodes().first(where: { $0.id == nextId }) {
            return node.name
        } else {
            return nextId // fallback
        }
    }

    // Helper for previous node name
    private func prevNodeName(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        let prevId = computePrevNodeID(for: closest, segments: segments)
        guard !prevId.isEmpty else { return "" }
        if let node = loadNodes().first(where: { $0.id == prevId }) {
            return node.name
        } else {
            return prevId
        }
    }

    // Pure function to compute next node ID
    private func computeNextNodeID(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        switch navModel.planState {
        case .idle:
            return navModel.currentPlan.first ?? ""
        case .active, .offRoute:
            guard let closest = closest else { return "" }
            let plan = navModel.currentPlan
            let planIndex = closest.planIndex
            guard planIndex >= 0, planIndex + 1 < plan.count else { return "" }
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex+1]
            let dir = computeSegmentDirection(nodeAName: nodeAName, nodeBName: nodeBName, segments: segments)
            return dir == +1 ? plan[planIndex+1] : plan[planIndex]
        }
    }

    // Pure function to compute previous node ID
    private func computePrevNodeID(for closest: ClosestPointResult?, segments: [Segment]) -> String {
        switch navModel.planState {
        case .idle:
            return ""
        case .active, .offRoute:
            guard let closest = closest else { return "" }
            let plan = navModel.currentPlan
            let planIndex = closest.planIndex
            guard planIndex >= 0, planIndex + 1 < plan.count else { return "" }
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex+1]
            let dir = computeSegmentDirection(nodeAName: nodeAName, nodeBName: nodeBName, segments: segments)
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
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex + 1]
            let direction = computeSegmentDirection(nodeAName: nodeAName, nodeBName: nodeBName, segments: segments)
            let dist = distanceToNextNode(closest: closest, segments: segments, direction: direction)
            return String(format: "%.0f", dist)
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
            guard let closest = closest else { return "0" }
            let plan = navModel.currentPlan
            let planIndex = closest.planIndex
            guard planIndex >= 0, planIndex + 1 < plan.count else { return "0" }
            let nodeAName = plan[planIndex]
            let nodeBName = plan[planIndex + 1]
            let direction = computeSegmentDirection(nodeAName: nodeAName, nodeBName: nodeBName, segments: segments)
            let elevChange = elevationChangeToNextNode(closest: closest, segments: segments, direction: direction)
            return String(format: "%.0f", elevChange)
        }
    }

    var body: some View {
        Group {
            
            let segments = loadSegments()
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
                        Text("ELEV: \(elevationString(for: closest, segments: segments))")
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
                updatePlanState(distance: closest?.distance, navModel: navModel)
                navModel.nextNodeID = computeNextNodeID(for: closest, segments: segments)
                navModel.prevNodeID = computePrevNodeID(for: closest, segments: segments)
            }
            .onReceive(locationManager.$coordinate) { _ in
                updatePlanState(distance: closest?.distance, navModel: navModel)
                navModel.nextNodeID = computeNextNodeID(for: closest, segments: segments)
                navModel.prevNodeID = computePrevNodeID(for: closest, segments: segments)
            }
        }
    }
}

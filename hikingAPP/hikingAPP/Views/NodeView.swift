//
//  NodeView.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/10/2.
//
import Foundation
import CoreLocation
import SwiftUI

// Represents the current segment the user is on, with points ordered in travel direction
struct CurrentSegmentResult {
    let segment: Segment          // original JSON segment (for elevation, etc.)
    let points: [Point]           // ordered in user travel direction
    let planIndex: Int            // where user is in the plan
    let closestIndex: Int         // index along `points` the user is nearest to
}

struct NodeInfoPanel: View {
    @EnvironmentObject var navModel: NavigationViewModel
    @EnvironmentObject var locationManager: LocationManager
    /*
    private func computeSegmentDirection(nodeAName: String, nodeBName: String, segments: [Segment], nodes: [Node]) -> Int {
        let segId = node2seg(nodeAName, nodeBName)
        let revSegId = node2seg(nodeBName, nodeAName)
        let segmentIds = segments.map { $0.id }
        let storedDirection: Int
        if segmentIds.contains(segId) { storedDirection = +1 }
        else if segmentIds.contains(revSegId) { storedDirection = -1 }
        else { storedDirection = +1 }

        let userLocs = locationManager.locationHistory + (locationManager.coordinate.map { [$0] } ?? [])
        return detectDirection(nodeAID: nodeAName, nodeBID: nodeBName, userLocations: userLocs, segments: segments) * storedDirection
    }
     */
    
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
     
    // Helper: compute the current segment in user's travel direction
    private func computeCurrentSegment(for closest: ClosestPointResult?, segments: [Segment]) -> CurrentSegmentResult? {
        guard let closest = closest else { return nil }
        guard let seg = segments.first(where: { $0.id == closest.validSegmentID }) else { return nil }
        // order points so they are in the user's travel direction
        let orderedPoints = (closest.userDirection == +1)
            ? seg.points
            : Array(seg.points.reversed())

        // Compute index AFTER ordering
        let closestIdx = findClosestPointIndex(points: orderedPoints, to: closest.point)

        return CurrentSegmentResult(
            segment: seg,
            points: orderedPoints,
            planIndex: closest.planIndex,
            closestIndex: closestIdx
        )
    }

    // Helper: find closest index in an array of points to a reference point
    private func findClosestPointIndex(points: [Point], to point: Point) -> Int {
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

    // Helper: compute distance to the end of current segment using normalized direction
    private func distChangetoNextNode(current: CurrentSegmentResult) -> Double {
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

    // Helper: compute elevation change to end of current segment using normalized direction
    private func elevChangetoNextNode(current: CurrentSegmentResult) -> Double {
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
    
    // Helper for next node name
    private func nextNodeName(for closest: ClosestPointResult?, nodes: [Node]) -> String {
        guard let closest,
              closest.planIndex + 1 < navModel.currentPlan.count
        else { return "" }

        let nextID = navModel.currentPlan[closest.planIndex + 1]
        return nodes.first(where: { $0.id == nextID })?.name ?? nextID
    }
    
    // Helper for previous node name
    private func prevNodeName(for closest: ClosestPointResult?, nodes: [Node]) -> String {
        guard let closest,
              closest.planIndex < navModel.currentPlan.count
        else { return "" }

        let prevID = navModel.currentPlan[closest.planIndex]
        return nodes.first(where: { $0.id == prevID })?.name ?? prevID
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
                let dist = distChangetoNextNode(current: current)
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
                let elevChange = elevChangetoNextNode(current: current)
                return String(format: "%.0f", elevChange)
            }
            return "0"
        }
    }
    
    var body: some View {
        Group {
            
            let segments = loadSegments()
            let nodes = loadNodes()
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
                ){
                    // Next Node capsule
                    Text(nextNodeName(for: closest, nodes: nodes))
                        .font(.caption)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                        .foregroundColor(.white)
                }.simultaneousGesture(TapGesture().onEnded {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                })
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
                        Text("ELEV: \(elevationString(for: closest, segments: segments)) m")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                NavigationLink(destination:
                                PlanDisplayView(
                                    navModel: navModel,
                                    title: navModel.currentPlan.isEmpty ? "目前沒有計劃" : "目前路線",
                                    route: navModel.currentPlan,
                                    nodes: nodes
                                )
                ){
                    // Previous Node capsule
                    Text(prevNodeName(for: closest, nodes: nodes))
                        .font(.caption)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                        .foregroundColor(.white)
                }.simultaneousGesture(TapGesture().onEnded {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                })
                
            }
            .padding(.bottom, 20)
            .scaleEffect(1.5)
            .onAppear {
                updatePlanState(distance: closest?.distance, navModel: navModel)
                if let closest = closest,
                   closest.planIndex + 1 < navModel.currentPlan.count {
                    navModel.nextNodeID = navModel.currentPlan[closest.planIndex + 1]
                    navModel.prevNodeID = navModel.currentPlan[closest.planIndex]
                }
                if navModel.planState == .active, let closest = closest, let current = computeCurrentSegment(for: closest, segments: segments) {
                    let remaining = distChangetoNextNode(current: current)
                    navModel.segmentDistanceLeft = remaining
                }
            }
            .onReceive(locationManager.$coordinate) { _ in
                updatePlanState(distance: closest?.distance, navModel: navModel)
                if let closest = closest,
                   closest.planIndex + 1 < navModel.currentPlan.count {
                    navModel.nextNodeID = navModel.currentPlan[closest.planIndex + 1]
                    navModel.prevNodeID = navModel.currentPlan[closest.planIndex]
                }
                if navModel.planState == .active, let closest = closest, let current = computeCurrentSegment(for: closest, segments: segments) {
                    let remaining = distChangetoNextNode(current: current)
                    navModel.segmentDistanceLeft = remaining
                }
            }
        }
    }
}
struct PlanDisplayView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var navModel: NavigationViewModel
    var title: String
    var route: [String]
    var nodes: [Node]
    @State private var showResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if title == "目前沒有計劃" {
                VStack {
                    Text(title)
                        .font(.title)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    Spacer()
                }
            } else {
                Text("DAY \(navModel.dayIndex + 1)")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)
                
                Text(title)
                    .font(.title2)
                    .padding(.bottom, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(route, id: \.self) { id in
                            if let node = nodes.first(where: { $0.id == id }) {
                                Text(node.name)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            } else {
                                Text(id)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.leading, 10)
                .scaleEffect(1.15)
                
                HStack(spacing: 40) {
                    Button {
                        if navModel.dayIndex > 0 {
                            navModel.setCurrentDay(navModel.dayIndex - 1)
                        }
                    } label: {
                        Text("Prev Day")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.35))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]] ?? []
                        if navModel.dayIndex + 1 < savedHistory.count {
                            navModel.setCurrentDay(navModel.dayIndex + 1)
                        }
                    } label: {
                        Text("Next Day")
                            .font(.title3.bold())
                            .padding(.horizontal, 28)
                            .padding(.vertical, 10)
                            .background(Color.blue.opacity(0.35))
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 14)
                
                // Full multi-day plan list
                Text("所有計劃")
                    .font(.headline)
                    .padding(.vertical, 6)
                let savedHistory = UserDefaults.standard.array(forKey: "PlanHistory") as? [[String]] ?? []
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(savedHistory.enumerated()), id: \.offset) { (index, dayPlan) in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Text("Day \(index + 1)")
                                        .font(.footnote)
                                        .foregroundColor(.yellow)
                                    if index == navModel.dayIndex {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.red)
                                            .font(.footnote.bold())
                                    }
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(dayPlan, id: \.self) { id in
                                            if let node = nodes.first(where: { $0.id == id }) {
                                                Text(node.name)
                                                    .font(.caption)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(Color.gray.opacity(0.15))
                                                    .cornerRadius(3)
                                            } else {
                                                Text(id)
                                                    .font(.caption)
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red.opacity(0.15))
                                                    .cornerRadius(3)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 6)
                        }
                    }
                }
                .padding(.top, 6)
                
                Spacer()
                Button {
                    showResetAlert = true
                } label: {
                    HStack{
                        Label("重設計劃", systemImage: "arrow.clockwise.circle")
                            .foregroundStyle(Color.white)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.7))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .alert("確定要刪除目前計劃嗎？", isPresented: $showResetAlert) {
                    Button("取消", role: .cancel) {}
                    Button("刪除", role: .destructive) {
                        navModel.currentPlan = []
                        UserDefaults.standard.removeObject(forKey: "CurrentDayIndex")
                        UserDefaults.standard.removeObject(forKey: "PlanHistory")
                        dismiss()
                    }
                }
            }   // end of else
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}



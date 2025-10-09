import SwiftUI
import CoreLocation
import Combine

let nodethreshhold: Double = 50

struct ClosestNodeResult {
    let node: Node
    let distance: Double
}



class ETAViewModel: ObservableObject {
    @Published var isTiming = false
    @Published var isInsideNode = true
    var onSegmentCompleted: ((String, String, TimeInterval) -> Void)?
    var leavingNodeID: String? = nil
    var enteringNodeID: String? = nil
    private var startTime: Date? = nil
    private var accumulatedTime: TimeInterval = 0
    
    func updateTiming(closestNode: ClosestNodeResult) {
        let distance = closestNode.distance
        let nodeID = closestNode.node.id
        
        if isInsideNode && distance > nodethreshhold {
            // User just left the node
            leavingNodeID = nodeID
            isInsideNode = false
            startTimer()
            startTime = Date()
        } else if !isInsideNode && distance <= nodethreshhold {
            // User entered a node
            enteringNodeID = nodeID
            isInsideNode = true
            stopTimer()
            if let fromID = leavingNodeID, let toID = enteringNodeID {
                    onSegmentCompleted?(fromID, toID, elapsedTime)
                }
        }
        // otherwise do nothing, keep timer running
    }
    
    func startTimer() {
        guard !isTiming else { return }
        isTiming = true
        startTime = Date()
    }
    
    func stopTimer() {
        isTiming = false
        if let start = startTime {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        startTime = nil
    }
    
    var elapsedTime: TimeInterval {
        if let start = startTime {
            return accumulatedTime + Date().timeIntervalSince(start)
        } else {
            return accumulatedTime
        }
    }
}



struct ETAView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var viewModel = ETAViewModel()
    @EnvironmentObject var navModel: NavigationViewModel
    

    
    var body: some View {

        let segments = loadSegments()
        let user = loadUser() ?? User(id: UUID(), username: "josh", speedFactor: 1.0)
        
        // Compute etaMinutes outside of ViewBuilder
        // Compute etaMinutes outside of ViewBuilder
        let etaMinutes: Double = {
            guard let fromID = navModel.prevNodeID, !fromID.isEmpty else { return 0 }
            guard let nextNodeID = navModel.nextNodeID, !nextNodeID.isEmpty,
                  let stdTime = standardTimeBetweenNodes(fromNodeID: fromID, toNodeID: nextNodeID, segments: segments)
            else { return 0 }

            // total distance of the current segment (in meters)
            let totalDistance = totalSegmentDistance(from: fromID, to: nextNodeID, segments: segments)
            // remaining distance dynamically updated by NodeView
            let remainingDistance = navModel.segmentDistanceLeft
            // ratio of how much of the segment remains (clamped 0–1)
            let fractionRemaining = max(0, min(1, remainingDistance / totalDistance))

            // scale ETA by remaining distance
            return stdTime * user.speedFactor * fractionRemaining
        }()
        
        VStack {
            Text("ETA : \(Int(etaMinutes)) mins")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .offset(y: 110)
                    .fontWeight(.bold)
                    .opacity(navModel.planState != .idle ? 1 : 0) // Reserve space, hide when idle
            
            if let result = closestNode(from: locationManager.coordinate, nodes: loadNodes()) {
                
                VStack {
                    /*
                    Text("Distance to node: \(Int(result.distance)) m")
                        .foregroundColor(.white)
                    Text("Timer: \(Int(viewModel.elapsedTime)) s")
                        .foregroundColor(.white)*/
                }
                .onAppear {
                    viewModel.onSegmentCompleted = { fromID, toID, elapsed in
                        let segments = loadSegments()
                        if let stdTime = standardTimeBetweenNodes(fromNodeID: fromID, toNodeID: toID, segments: segments) {
                            let userTime = elapsed / 60.0 // seconds → minutes
                            let userSpeedFactor = userTime / stdTime

                            if userSpeedFactor >= 0.1 && userSpeedFactor <= 2.0 {
                                var user = loadUser() ?? User(id: UUID(), username: "josh", speedFactor: 1.0)
                                var recents = user.recentSpeedFactors ?? []
                                recents.append(userSpeedFactor)
                                if recents.count > 5 { recents.removeFirst(recents.count - 5) }
                                user.recentSpeedFactors = recents
                                user.speedFactor = recents.reduce(0, +) / Double(recents.count)
                                saveUser(user)
                                print("✅ User speed factor updated: \(user.speedFactor)")
                            } else {
                                print("❌ Discarded outlier speed factor: \(userSpeedFactor)")
                            }
                        }
                    }
                }
                .onReceive(locationManager.$coordinate.compactMap { $0 }) { _ in
                    if navModel.planState == .active {
                        viewModel.updateTiming(closestNode: result)
                    }
                }
            } else {
                Text("No location")
                    .foregroundColor(.gray)
            }
        }
    }
}
func totalSegmentDistance(from fromID: String, to toID: String, segments: [Segment]) -> Double {
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


#Preview {
    ETAView()
        .environmentObject(NavigationViewModel())
        .environmentObject(LocationManager())
        .frame(width: 300, height: 300)
        .background(Color.black)
        
}

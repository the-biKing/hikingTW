import SwiftUI
import CoreLocation
import Combine

let nodethreshhold: Double = 50

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
        let segments = SegmentDataManager.shared.getAllLoadedSegments()
        let user = PersistenceManager.shared.loadUser() ?? User(id: UUID(), username: "josh", speedFactor: 1.0)
        
        let etaMinutes: Double = {
            guard let fromID = navModel.prevNodeID, !fromID.isEmpty else { return 0 }
            guard let nextNodeID = navModel.nextNodeID, !nextNodeID.isEmpty,
                  let stdTime = TimeCalculator.standardTimeBetweenNodes(fromNodeID: fromID, toNodeID: nextNodeID, segments: segments)
            else { return 0 }

            let totalDistance = NavigationUtils.totalSegmentDistance(from: fromID, to: nextNodeID, segments: segments)
            let remainingDistance = navModel.segmentDistanceLeft
            let fractionRemaining = max(0, min(1, remainingDistance / totalDistance))

            return stdTime * user.speedFactor * fractionRemaining
        }()
        
        VStack {
            Text("ETA : \(Int(etaMinutes)) mins")
                .font(.largeTitle)
                .foregroundColor(AppColors.text)
                .padding(.bottom, 20)
                .offset(y: 110)
                .fontWeight(.bold)
                .opacity(navModel.planState != .idle ? 1 : 0)
            
            if let result = NavigationUtils.closestNode(from: locationManager.coordinate, nodes: PersistenceManager.shared.loadNodes()) {
                VStack {
                    // Progress info could go here
                }
                .onAppear {
                    viewModel.onSegmentCompleted = { fromID, toID, elapsed in
                        let currentSegments = SegmentDataManager.shared.getAllLoadedSegments()
                        if let stdTime = TimeCalculator.standardTimeBetweenNodes(fromNodeID: fromID, toNodeID: toID, segments: currentSegments) {
                            let userTime = elapsed / 60.0
                            let userSpeedFactor = userTime / stdTime

                            if userSpeedFactor >= 0.1 && userSpeedFactor <= 2.0 {
                                var currentUser = PersistenceManager.shared.loadUser() ?? User(id: UUID(), username: "josh", speedFactor: 1.0)
                                var recents = currentUser.recentSpeedFactors ?? []
                                recents.append(userSpeedFactor)
                                if recents.count > 5 { recents.removeFirst(recents.count - 5) }
                                currentUser.recentSpeedFactors = recents
                                currentUser.speedFactor = recents.reduce(0, +) / Double(recents.count)
                                PersistenceManager.shared.saveUser(currentUser)
                                print("✅ User speed factor updated: \(currentUser.speedFactor)")
                            }
                            navModel.tryAdvanceDay(completedSegment: (fromID, toID))
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
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

#Preview {
    ETAView()
        .environmentObject(NavigationViewModel())
        .environmentObject(LocationManager())
        .frame(width: 300, height: 300)
        .background(AppColors.background)
}

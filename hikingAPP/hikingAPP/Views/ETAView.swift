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
        let etaMinutes: Double = {
            guard let fromID = navModel.prevNodeID, !fromID.isEmpty else { return 0 }
            guard let nextNodeID = navModel.nextNodeID, !nextNodeID.isEmpty,
                  let stdTime = standardTimeBetweenNodes(fromNodeID: fromID, toNodeID: nextNodeID, segments: segments)
            else { return 0 }
            return stdTime * user.speedFactor
        }()
        
        VStack {
            if navModel.planState != .idle {
                Text("ETA : \(Int(etaMinutes)) mins")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .offset(y: 110)
                    .fontWeight(.bold)
            }
            else{
                
            }
            
            
            if let result = closestNode(from: locationManager.coordinate, nodes: loadNodes()) {
                VStack {
                    Text("Distance to node: \(Int(result.distance)) m")
                        .foregroundColor(.white)
                    Text("Timer: \(Int(viewModel.elapsedTime)) s")
                        .foregroundColor(.white)
                }
                .onAppear {
                    if navModel.planState == .active {
                        viewModel.updateTiming(closestNode: result)
                    }
                    // Example usage: compare actual and standard segment time
                    if let fromID = viewModel.leavingNodeID,
                       let toID = viewModel.enteringNodeID {
                        let segments = loadSegments()
                        if let stdTime = standardTimeBetweenNodes(fromNodeID: fromID, toNodeID: toID, segments: segments) {
                            let userTime = viewModel.elapsedTime / 60.0 // convert seconds to minutes
                            let userSpeedFactor = userTime / stdTime
                            
                            if userSpeedFactor >= 0.1 && userSpeedFactor <= 2.0 {
                                var user = loadUser() ?? User(id: UUID(), username: "josh", speedFactor: 1.0)
                                
                                // Maintain recent factors
                                var recents = user.recentSpeedFactors ?? []
                                recents.append(userSpeedFactor)
                                if recents.count > 5 {
                                    recents.removeFirst(recents.count - 5)
                                }
                                user.recentSpeedFactors = recents
                                
                                // Update average speed factor
                                let avg = recents.reduce(0, +) / Double(recents.count)
                                user.speedFactor = avg
                                
                                saveUser(user)
                                print("User speed factor saved: \(avg)")
                            } else {
                                print("❌ Discarded outlier speed factor: \(userSpeedFactor)")
                            }
                        }
                    }
                }
                .onReceive(Just(result.distance)) { _ in
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



#Preview {
    ETAView()
        .environmentObject(NavigationViewModel())
        .environmentObject(LocationManager())
        .frame(width: 300, height: 300)
        .background(Color.black)
        
}

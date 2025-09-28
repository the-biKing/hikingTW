//
//  ETAView.swift
//  hikingAPP
//
//  Created by 謝喆宇 on 2025/9/28.
//
//TODO test
import SwiftUI
import CoreLocation
import Combine

let nodethreshhold: Double = 50

struct ClosestNodeResult {
    let node: Node
    let distance: Double
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

class ETAViewModel: ObservableObject {
    @Published var isTiming = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var isInsideNode = true
    @Published var currentNodeID: String? = nil
    var leavingNodeID: String? = nil
    var enteringNodeID: String? = nil
    private var timer: Timer?
    
    func updateTiming(closestNode: ClosestNodeResult) {
        let distance = closestNode.distance
        let nodeID = closestNode.node.id
        
        if isInsideNode && distance > nodethreshhold {
            // User just left the node
            leavingNodeID = currentNodeID
            currentNodeID = nil
            isInsideNode = false
            startTimer()
        } else if !isInsideNode && distance <= nodethreshhold {
            // User entered a node
            enteringNodeID = nodeID
            currentNodeID = nodeID
            isInsideNode = true
            stopTimer()
        }
        // otherwise do nothing, keep timer running
    }
    
    func startTimer() {
        guard !isTiming else { return }
        isTiming = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.elapsedTime += 1
        }
    }
    
    func stopTimer() {
        isTiming = false
        timer?.invalidate()
        timer = nil
    }
}

// Helper to get standard time between two nodes based on segment direction
func standardTimeBetweenNodes(fromNodeID: String, toNodeID: String, segments: [Segment]) -> Double? {
    let forwardID = "\(fromNodeID)_\(toNodeID)"
    let reverseID = "\(toNodeID)_\(fromNodeID)"
    
    if let seg = segments.first(where: { $0.id == forwardID }) {
        return seg.standardTime
    } else if let seg = segments.first(where: { $0.id == reverseID }) {
        return seg.revStandardTime
    } else {
        return nil
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
            guard let fromID = viewModel.currentNodeID, !fromID.isEmpty else { return 0 }
            let nodes = loadNodes()
            let userLocations = locationManager.locationHistory + (locationManager.coordinate.map { [$0] } ?? [])
            let nextNodeID = nextNodeName(
                currentNodeID: fromID,
                plan: navModel.currentPlan,
                segments: segments,
                userLocations: userLocations,
                nodes: nodes
            )
            guard !nextNodeID.isEmpty,
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
                            print("Standard time from \(fromID) to \(toID): \(stdTime) minutes")
                            
                            // Calculate user's speed factor
                            let userTime = viewModel.elapsedTime / 60.0 // convert seconds to minutes
                            let userSpeedFactor = userTime / stdTime
                            
                            // Load or create user
                            var user = loadUser() ?? User(id: UUID(), username: "josh", speedFactor: 1.0)
                            user.speedFactor = userSpeedFactor
                            
                            // Save back to JSON
                            saveUser(user)
                            print("User speed factor saved: \(userSpeedFactor)")
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

// MARK: - Next Node Name Helper for ETA
/// Returns the next node name in the plan based on movement direction, independent of any View or model.
private func nextNodeName(
    currentNodeID: String?,
    plan: [String],
    segments: [Segment],
    userLocations: [CLLocationCoordinate2D],
    nodes: [Node]
) -> String {
    guard let currentNodeID = currentNodeID,
          let currentIndex = plan.firstIndex(of: currentNodeID) else { return plan.first ?? "" }
    
    // Determine the next index in the plan
    var nextIndex: Int
    if currentIndex + 1 < plan.count {
        nextIndex = currentIndex + 1
    } else {
        nextIndex = currentIndex
    }
    
    let nodeAName = plan[currentIndex]
    let nodeBName = plan[nextIndex]
    
    guard let nodeA = nodes.first(where: { $0.id == nodeAName }),
          let nodeB = nodes.first(where: { $0.id == nodeBName }) else { return "" }
    
    let nodeACoord = CLLocationCoordinate2D(latitude: nodeA.latitude, longitude: nodeA.longitude)
    let nodeBCoord = CLLocationCoordinate2D(latitude: nodeB.latitude, longitude: nodeB.longitude)
    
    // Determine stored segment direction (+1 or -1)
    let segId = node2seg(nodeAName, nodeBName)
    let revSegId = node2seg(nodeBName, nodeAName)
    let segmentIds = segments.map { $0.id }
    let storedDirection: Int
    if segmentIds.contains(segId) {
        storedDirection = +1
    } else if segmentIds.contains(revSegId) {
        storedDirection = -1
    } else {
        storedDirection = +1
    }
    
    let dir = detectDirection(userLocations: userLocations, nodeA: nodeACoord, nodeB: nodeBCoord) * storedDirection
    return dir == +1 ? nodeBName : nodeAName
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

#Preview {
    ETAView()
        .environmentObject(NavigationViewModel())
        .environmentObject(LocationManager())
        .frame(width: 300, height: 300)
        .background(Color.black)
        
}

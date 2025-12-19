import Foundation
import SwiftUI

class GraphViewModel: ObservableObject {
    @Published var nodes: [Node] = []
    @Published var segments: [Segment] = []
    @Published var estimatedTime: Double = 0.0
    @Published var startNodes: [Node] = []
    @Published var current: Node?
    @Published var path: [String] = []
    @Published var history: [[String]] = [] {
        didSet { saveHistory() }
    }
    
    private var lookup: [String: Node] = [:]
    private var areaCodes: [String]
    private var start: Node?
    
    init(areaCodes: [String]) {
        self.areaCodes = areaCodes.map { $0.uppercased() }
        let allNodes = PersistenceManager.shared.loadNodes()
        self.nodes = allNodes
        self.segments = SegmentDataManager.shared.getSegments(forAreaCodes: self.areaCodes)
        
        self.lookup = Dictionary(uniqueKeysWithValues: allNodes.map { ($0.id, $0) })
        
        self.startNodes = allNodes.filter { node in
            let id = node.id.uppercased()
            guard id.hasPrefix("S_") else { return false }
            return areaCodes.contains { code in
                id.contains("_\(code)_") || id.hasSuffix("_\(code)")
            }
        }
    }
    
    func setStart(_ node: Node) {
        self.start = node
        self.current = node
        self.path = [node.id]
    }
    
    func move(to nextId: String) {
        if let nextNode = lookup[nextId], let current = current {
            withAnimation(.easeInOut) {
                self.current = nextNode
                self.path.append(nextNode.id)
                self.estimatedTime += timeBetween(current.id, nextNode.id)
            }
        }
    }
    
    func goBack() {
        guard path.count > 1 else { return }
        let removedId = path.removeLast()
        if let lastId = path.last,
           let lastNode = lookup[lastId] {
            withAnimation(.easeInOut) {
                self.current = lastNode
                let timeToSubtract = timeBetween(lastId, removedId)
                self.estimatedTime = max(0, self.estimatedTime - timeToSubtract)
            }
        }
    }
    
    func reset() {
        guard let now = current else { return }
        if !path.isEmpty {
            history.append(path)
        }
        withAnimation(.easeInOut) {
            self.start = now
            self.path = [now.id]
            self.current = now
            self.estimatedTime = 0.0
        }
    }
    
    func timeBetween(_ from: String, _ to: String) -> Double {
        var time: Double = 0.0
        if let seg = segments.first(where: { $0.id == "\(from)_\(to)" }) {
            time = seg.standardTime
        } else if let seg = segments.first(where: { $0.id == "\(to)_\(from)" }) {
            time = seg.revStandardTime
        } else {
            print("⚠️ No segment found for \(from) ↔ \(to)")
            return 0.0
        }
        
        if let user = PersistenceManager.shared.loadUser() {
            return time * user.speedFactor
        } else {
            return time
        }
    }
    
    func deleteHistory(at index: Int) {
        guard history.indices.contains(index) else { return }
        history.remove(at: index)
        
        if let lastRoute = history.last,
           let lastId = lastRoute.last,
           let lastNode = lookup[lastId] {
            self.current = lastNode
            self.start = lastNode
            self.path = [lastNode.id]
        } else if let first = startNodes.first {
            self.current = first
            self.start = first
            self.path = [first.id]
        }
    }
    
    func saveHistory() {
        UserDefaults.standard.set(history, forKey: "PlanHistory")
    }
}

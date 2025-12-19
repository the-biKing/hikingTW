import Foundation
import CoreLocation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private init() {}
    
    // MARK: - User Persistence
    func getUserFileURL() -> URL? {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return docs.appendingPathComponent("user.json")
    }

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
    
    // MARK: - Node Loading
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
}

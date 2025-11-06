import Foundation
import Combine

enum BirdMarkStatus: String, Codable {
    case none
    case met
    case wantToFind
}

@MainActor
final class BirdMarkService: ObservableObject {
    static let shared = BirdMarkService()
    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: BirdMarkStatus].self, from: data) {
            birdIdToStatus = decoded
        }
    }
    
    private let storageKey = "bird_mark_status_storage"
    
    @Published private(set) var birdIdToStatus: [String: BirdMarkStatus] = [:]
    
    func status(forKey key: String) -> BirdMarkStatus {
        return birdIdToStatus[key] ?? .none
    }
    
    func setStatus(_ status: BirdMarkStatus, forKey key: String) {
        birdIdToStatus[key] = status
        birdIdToStatus = birdIdToStatus
        persist()
    }
    
    func status(for birdId: UUID) -> BirdMarkStatus {
        return status(forKey: birdId.uuidString)
    }
    
    func setStatus(_ status: BirdMarkStatus, for birdId: UUID) {
        setStatus(status, forKey: birdId.uuidString)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(birdIdToStatus) {
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.synchronize()
        }
    }
}



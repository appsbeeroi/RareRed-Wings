import Combine
import SwiftUI

@MainActor
final class ObservationService: ObservableObject {
    
    static let shared = ObservationService()
    
    private init() {
        loadObservations()
    }
    
    private let storageKey = "personal_observations_storage"
    
    @Published private(set) var observations: [PersonalObservation] = []
    @Published var selectedObservation: PersonalObservation? = nil
    
    // MARK: - Public API
    
    func addObservation(_ observation: PersonalObservation) {
        observations.append(observation)
        saveObservations()
    }
    
    func removeObservation(_ observation: PersonalObservation) {
        observations.removeAll { $0.id == observation.id }
        saveObservations()
    }
    
    func updateObservation(_ observation: PersonalObservation) {
        if let index = observations.firstIndex(where: { $0.id == observation.id }) {
            observations[index] = observation
            saveObservations()
        }
    }
    
    var hasObservations: Bool {
        !observations.isEmpty
    }
    
    func removeAll() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        observations = []
    }
        
    private func loadObservations() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PersonalObservation].self, from: data) else {
            return
        }
        observations = decoded
    }
    
    private func saveObservations() {
        if let data = try? JSONEncoder().encode(observations) {
            UserDefaults.standard.set(data, forKey: storageKey)
            UserDefaults.standard.synchronize()
        }
    }
}

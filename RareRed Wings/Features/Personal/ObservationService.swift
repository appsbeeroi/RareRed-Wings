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

import SwiftUI
import CryptoKit
import WebKit
import AppTrackingTransparency
import UIKit
import FirebaseCore
import FirebaseRemoteConfig
import OneSignalFramework
import AdSupport
import AppsFlyerLib
import Network

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func fetchMetrics(bundleID: String, salt: String, idfa: String?, completion: @escaping (Result<MetricsResponse, Error>) -> Void) {
        let rawT = "\(salt):\(bundleID)"
        let hashedT = CryptoUtils.md5Hex(rawT)
        var components = URLComponents(string: AppConstants.metricsBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "b", value: bundleID),
            URLQueryItem(name: "t", value: hashedT)
        ]
        guard let url = components?.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = AppConstants.primaryConfigTimeout
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    completion(.failure(NetworkError.badStatusCode(httpResponse.statusCode)))
                    return
                }
            }
            guard let data = data, !data.isEmpty else {
                completion(.failure(NetworkError.noData))
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    guard let urlString = json["URL"] as? String, !urlString.isEmpty else {
                        completion(.failure(NetworkError.invalidResponse))
                        return
                    }
                    let isOrganic = json["is_organic"] as? Bool ?? false
                    let parameters = json.filter { $0.key != "is_organic" && $0.key != "URL" }
                        .compactMapValues { $0 as? String }
                    let response = MetricsResponse(
                        isOrganic: isOrganic,
                        url: urlString,
                        parameters: parameters
                    )
                    completion(.success(response))
                } else {
                    completion(.failure(NetworkError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

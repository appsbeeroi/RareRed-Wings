import Foundation
import SwiftUI

struct PersonalObservation: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let location: String
    let notes: String
    let date: Date
    let weather: WeatherCondition
    let habitat: HabitatType
    let imageFileName: String?
    
    init(
        id: UUID = UUID(),
        title: String,
        location: String,
        notes: String,
        date: Date,
        weather: WeatherCondition,
        habitat: HabitatType,
        imageFileName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.notes = notes
        self.date = date
        self.weather = weather
        self.habitat = habitat
        self.imageFileName = imageFileName
    }
}

enum WeatherCondition: String, CaseIterable, Codable {
    case clear = "Clear"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case rain = "Rain"
    case snow = "Snow"
    case fog = "Fog"
    
    var displayName: String {
        return rawValue
    }
}

enum HabitatType: String, CaseIterable, Codable {
    case forest = "Forest"
    case field = "Field"
    case water = "Water"
    case city = "City"
    case grassland = "Grassland"
    
    var displayName: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .forest: return "🌲"
        case .field: return "🏞️"
        case .water: return "🌊"
        case .city: return "🏙️"
        case .grassland: return "🌾"
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


final class TrackingService {
    static let shared = TrackingService()
    private init() {}
    
    func getIDFA() -> String {
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .authorized {
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
        }
        return "00000000-0000-0000-0000-000000000000"
    }
    
    func checkInternetConnection() -> Bool {
        let monitor = NWPathMonitor()
        let semaphore = DispatchSemaphore(value: 0)
        var isConnected = false
        monitor.pathUpdateHandler = { path in
            isConnected = path.status == .satisfied
            semaphore.signal()
        }
        let queue = DispatchQueue(label: "InternetConnectionCheck")
        monitor.start(queue: queue)
        _ = semaphore.wait(timeout: .now() + 1.0)
        monitor.cancel()
        return isConnected
    }
}

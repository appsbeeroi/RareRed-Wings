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

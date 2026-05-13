//
//  WeatherModel.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/5/26.
//

import Foundation
import CoreLocation

// MARK: - App Model (clean, UI-ready)
struct WeatherModel {
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let conditionCode: Int
    let windSpeed: Double
    let windDirection: Int
    let humidity: Int
    let visibility: Double
    let cityName: String
    let coordinate: CLLocationCoordinate2D
    let fetchedAt: Date

    var temperatureCelsius: Double { temperature }
    var temperatureFahrenheit: Double { temperature * 9 / 5 + 32 }

    func formattedTemperature(unit: TemperatureUnit) -> String {
        switch unit {
        case .celsius:    return String(format: "%.1f°C", temperatureCelsius)
        case .fahrenheit: return String(format: "%.1f°F", temperatureFahrenheit)
        }
    }

    var formattedWindSpeed: String {
        String(format: "%.1f km/h", windSpeed)
    }

    var conditionIcon: String {
        switch conditionCode {
        case 200...232: return "cloud.bolt.rain.fill"
        case 300...321: return "cloud.drizzle.fill"
        case 500...504: return "cloud.rain.fill"
        case 511:       return "cloud.sleet.fill"
        case 520...531: return "cloud.heavyrain.fill"
        case 600...622: return "cloud.snow.fill"
        case 701...781: return "cloud.fog.fill"
        case 800:       return "sun.max.fill"
        case 801...802: return "cloud.sun.fill"
        case 803...804: return "cloud.fill"
        default:        return "questionmark.circle"
        }
    }

    var formattedFetchTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: fetchedAt)
    }
}

// MARK: - Temperature Unit
enum TemperatureUnit: String, CaseIterable {
    case celsius    = "°C"
    case fahrenheit = "°F"
    var label: String { rawValue }
}

// MARK: - OpenWeatherMap API Response (Codable)
struct OWMResponse: Decodable {
    let name: String
    let coord: OWMCoord
    let weather: [OWMWeather]
    let main: OWMMain
    let wind: OWMWind
    let visibility: Int?
    let dt: TimeInterval

    struct OWMCoord: Decodable {
        let lat: Double
        let lon: Double
    }
    struct OWMWeather: Decodable {
        let id: Int
        let description: String
    }
    struct OWMMain: Decodable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
    }
    struct OWMWind: Decodable {
        let speed: Double
        let deg: Int?
    }

    func toWeatherModel() -> WeatherModel {
        WeatherModel(
            temperature:    main.temp,
            feelsLike:      main.feels_like,
            condition:      weather.first?.description.capitalized ?? "Unknown",
            conditionCode:  weather.first?.id ?? 800,
            windSpeed:      wind.speed * 3.6, // m/s → km/h
            windDirection:  wind.deg ?? 0,
            humidity:       main.humidity,
            visibility:     Double(visibility ?? 10000) / 1000,
            cityName:       name,
            coordinate:     CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lon),
            fetchedAt:      Date(timeIntervalSince1970: dt)
        )
    }
}

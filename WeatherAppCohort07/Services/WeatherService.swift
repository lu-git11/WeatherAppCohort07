//
//  WeatherService.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/5/26.
//

import Foundation
import CoreLocation

// MARK: - Protocol for testability
protocol WeatherServiceProtocol {
    func fetchWeather(coordinate: CLLocationCoordinate2D, unit: TemperatureUnit) async throws -> WeatherModel
}

// MARK: - WeatherService
final class WeatherService: WeatherServiceProtocol {

    // Using Open-Meteo (free, no API key needed) for demo reliability.
    // Swap baseURL + buildURL() to use OpenWeatherMap with an API key.
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchWeather(coordinate: CLLocationCoordinate2D, unit: TemperatureUnit) async throws -> WeatherModel {
        let url = try buildURL(coordinate: coordinate)
        let data = try await fetch(url: url)
        return try decode(data: data, coordinate: coordinate)
    }

    // MARK: - URL Construction (safe, no string-mashing)
    private func buildURL(coordinate: CLLocationCoordinate2D) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.open-meteo.com"
        components.path   = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude",               value: String(format: "%.6f", coordinate.latitude)),
            URLQueryItem(name: "longitude",              value: String(format: "%.6f", coordinate.longitude)),
            URLQueryItem(name: "current_weather",        value: "true"),
            URLQueryItem(name: "hourly",                 value: "relativehumidity_2m,visibility,apparent_temperature"),
            URLQueryItem(name: "wind_speed_unit",        value: "kmh"),
            URLQueryItem(name: "temperature_unit",       value: "celsius"),
            URLQueryItem(name: "timezone",               value: "auto"),
            URLQueryItem(name: "forecast_days",          value: "1"),
        ]
        guard let url = components.url else { throw AppError.invalidURL }
        return url
    }

    // MARK: - Network Fetch
    private func fetch(url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else { throw AppError.invalidURL }
             (200..<300)
            return data
        } catch let appErr as AppError {
            throw appErr
        } catch let urlErr as URLError {
            throw AppError.networkError(urlErr)
        } catch {
            throw AppError.unknown(error)
        }
    }

    // MARK: - Decoding
    private func decode(data: Data, coordinate: CLLocationCoordinate2D) throws -> WeatherModel {
        do {
            let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return response.toWeatherModel(coordinate: coordinate)
        } catch {
            throw AppError.decodingError(error)
        }
    }
}

// MARK: - Open-Meteo Response (Codable)
private struct OpenMeteoResponse: Decodable {
    let latitude:Double
    let longitude:Double
    let timezone:String
    let current_weather:CurrentWeather
    let hourly:HourlyData?

    struct CurrentWeather: Decodable {
        let time:String
        let temperature:Double
        let windspeed:Double
        let winddirection:Double
        let weathercode:Int
    }

    struct HourlyData: Decodable {
        let time:[String]
        let relativehumidity_2m:[Int]?
        let visibility:[Double]?
        let apparent_temperature:[Double]?
    }

    func toWeatherModel(coordinate: CLLocationCoordinate2D) -> WeatherModel {
        // Find the closest hourly index to current_weather.time
        let currentTime = current_weather.time
        let hourlyIndex = hourly?.time.firstIndex(of: currentTime) ?? 0

        let humidity    = hourly?.relativehumidity_2m?[safe: hourlyIndex] ?? 0
        let visibility  = (hourly?.visibility?[safe: hourlyIndex] ?? 10000) / 1000
        let feelsLike   = hourly?.apparent_temperature?[safe: hourlyIndex] ?? current_weather.temperature

        return WeatherModel(
            temperature:    current_weather.temperature,
            feelsLike:      feelsLike,
            condition:      wmoCodesToCondition(current_weather.weathercode),
            conditionCode:  wmoToOwmCode(current_weather.weathercode),
            windSpeed:      current_weather.windspeed,
            windDirection:  Int(current_weather.winddirection),
            humidity:       humidity,
            visibility:     visibility,
            cityName:       "Current Location",
            coordinate:     coordinate,
            fetchedAt:      Date()
        )
    }

    // WMO code → human-readable condition
    private func wmoCodesToCondition(_ code: Int) -> String {
        switch code {
        case 0:        return "Clear Sky"
        case 1:        return "Mainly Clear"
        case 2:        return "Partly Cloudy"
        case 3:        return "Overcast"
        case 45, 48:   return "Foggy"
        case 51...55:  return "Drizzle"
        case 56...57:  return "Freezing Drizzle"
        case 61...65:  return "Rain"
        case 66...67:  return "Freezing Rain"
        case 71...77:  return "Snow"
        case 80...82:  return "Rain Showers"
        case 85...86:  return "Snow Showers"
        case 95:       return "Thunderstorm"
        case 96, 99:   return "Thunderstorm with Hail"
        default:       return "Unknown"
        }
    }

    // WMO → approximate OWM-style code for icon mapping
    private func wmoToOwmCode(_ code: Int) -> Int {
        switch code {
        case 0, 1:      return 800
        case 2:         return 802
        case 3:         return 804
        case 45, 48:    return 741
        case 51...57:   return 300
        case 61...67:   return 500
        case 71...77:   return 600
        case 80...82:   return 520
        case 85...86:   return 620
        case 95...99:   return 200
        default:        return 800
        }
    }
}

// MARK: - Safe Array Index Extension
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

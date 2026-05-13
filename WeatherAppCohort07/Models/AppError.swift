//
//  AppError.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/13/26.
//

import Foundation

enum AppError: LocalizedError {
    case invalidURL
    case networkError(URLError)
    case decodingError(Error)
    case locationDenied
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not construct a valid request URL."
        case .networkError(let e) where e.code == .notConnectedToInternet:
            return "No internet connection. Please check your network and try again."
        case .networkError(let e) where e.code == .timedOut:
            return "The request timed out. Please try again."
        case .networkError:
            return "A network error occurred. Please try again."
        case .decodingError:
            return "Could not parse the weather data. Please try again."
        case .locationDenied:
            return "Location access is denied. Enable it in Settings to get weather for your location."
        case .unknown(let e):
            return "An unexpected error occurred: \(e.localizedDescription)"
        }
    }

    var isLocationPermissionError: Bool {
        switch self { case .locationDenied: return true; default: return false }
    }
}

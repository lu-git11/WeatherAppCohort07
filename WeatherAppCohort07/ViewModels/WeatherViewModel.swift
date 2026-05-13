//
//  WeatherViewModel.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/5/26.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {

    // MARK: - Published State
    @Published private(set) var weather:      WeatherModel?
    @Published private(set) var isLoading:    Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated:  Date?
    @Published var temperatureUnit:           TemperatureUnit = .celsius

    // MARK: - Dependencies
    private let service:         WeatherServiceProtocol
    private var cancellables:    Set<AnyCancellable> = []
    private var fetchTask:       Task<Void, Never>?

    // Throttle: ignore coordinate changes smaller than ~1 km
    private var lastFetchedCoordinate: CLLocationCoordinate2D?
    private let minimumDistanceMeters: Double = 1000

    init(service: WeatherServiceProtocol = WeatherService()) {
        self.service = service
    }

    // MARK: - Bind to LocationManager
    func bind(to locationManager: LocationManager) {
        locationManager.$lastCoordinate
            .compactMap { $0 }
            .removeDuplicates { [weak self] old, new in
                self?.shouldSkipFetch(from: old, to: new) ?? false
            }
            .sink { [weak self] coordinate in
                self?.fetchWeather(for: coordinate)
            }
            .store(in: &cancellables)
    }

    // MARK: - Fetch Weather
    func fetchWeather(for coordinate: CLLocationCoordinate2D) {
        fetchTask?.cancel()
        isLoading    = true
        errorMessage = nil

        fetchTask = Task {
            do {
                let result = try await service.fetchWeather(
                    coordinate: coordinate,
                    unit: temperatureUnit
                )
                guard !Task.isCancelled else { return }
                weather             = result
                lastUpdated         = Date()
                isLoading           = false
                lastFetchedCoordinate = coordinate
            } catch {
                guard !Task.isCancelled else { return }
                isLoading    = false
                errorMessage = (error as? AppError)?.errorDescription
                           ?? error.localizedDescription
            }
        }
    }

    // MARK: - Refresh (manual)
    func refresh(coordinate: CLLocationCoordinate2D?) {
        guard let coord = coordinate else {
            errorMessage = "Location not available yet. Please wait."
            return
        }
        lastFetchedCoordinate = nil // force re-fetch regardless of distance
        fetchWeather(for: coord)
    }

    // MARK: - Helpers
    private func shouldSkipFetch(from old: CLLocationCoordinate2D,
                                  to new: CLLocationCoordinate2D) -> Bool {
        let oldLoc = CLLocation(latitude: old.latitude, longitude: old.longitude)
        let newLoc = CLLocation(latitude: new.latitude, longitude: new.longitude)
        return newLoc.distance(from: oldLoc) < minimumDistanceMeters
    }

    var formattedCoordinate: String {
        guard let c = weather?.coordinate else { return "Locating…" }
        return String(format: "%.4f°, %.4f°", c.latitude, c.longitude)
    }

    var formattedLastUpdated: String {
        guard let d = lastUpdated else { return "Never" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: d, relativeTo: Date())
    }
}


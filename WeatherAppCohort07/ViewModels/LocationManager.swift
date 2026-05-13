//
//  LocationManager.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/13/26.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {

    // MARK: - Published State
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastCoordinate: CLLocationCoordinate2D?
    @Published private(set) var isLocating: Bool = false
    @Published private(set) var locationError: AppError?

    var isLocationAvailable: Bool { lastCoordinate != nil }

    // MARK: - Private
    private let manager = CLLocationManager()
    private var hasReceivedFirstFix = false

    override init() {
        super.init()
        manager.delegate          = self
        manager.desiredAccuracy   = kCLLocationAccuracyHundredMeters
        manager.distanceFilter    = 500 // only update if moved >500m
        authorizationStatus       = manager.authorizationStatus
    }

    // MARK: - Public API
    func requestPermissionAndStart() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        case .denied:
            locationError = .locationDenied
        @unknown default:
            break
        }
    }

    func startUpdating() {
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else { return }
        isLocating = true
        locationError = nil
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        isLocating = false
    }

    func retryLocation() {
        hasReceivedFirstFix = false
        locationError = nil
        requestPermissionAndStart()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationError = nil
                startUpdating()
            case .denied:
                locationError = .locationDenied
                stopUpdating()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy > 0,
              location.horizontalAccuracy < 5000 else { return }

        Task { @MainActor in
            lastCoordinate  = location.coordinate
            locationError   = nil
            isLocating      = false

            // One-shot mode: stop after first good fix
            if !hasReceivedFirstFix {
                hasReceivedFirstFix = true
                manager.stopUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            isLocating = false
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .locationDenied
                case .locationUnknown:
                    // Transient; keep trying
                    return
                default:
                    locationError = .locationDenied
                }
            } else {
                locationError = .unknown(error)
            }
        }
    }
}

// Views/ContentView.swift
import SwiftUI

struct WeatherView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherVM       = WeatherViewModel()

    var body: some View {
        ZStack {
            BackgroundGradientView(weatherCode: weatherVM.weather?.conditionCode)

            VStack(spacing: 0) {
                headerBar
                scrollContent
            }
        }
        .onAppear {
            weatherVM.bind(to: locationManager)
            locationManager.requestPermissionAndStart()
        }
        .onDisappear { locationManager.stopUpdating() }
    }

    // MARK: - Sub-views (routing only — no business logic here)

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch decideState() {
                case .permissionDenied:
                    PermissionDeniedView { locationManager.retryLocation() }

                case .locating:
                    LoadingView(message: "Locating you…")

                case .fetchingWeather:
                    LoadingView(message: "Fetching weather…")

                case .locationError(let msg):
                    ErrorView(message: msg, canRetry: true) {
                        locationManager.retryLocation()
                    }

                case .weatherError(let msg):
                    ErrorView(message: msg, canRetry: true) {
                        weatherVM.refresh(coordinate: locationManager.lastCoordinate)
                    }

                case .success(let weather):
                    WeatherCardView(weather: weather, unit: weatherVM.temperatureUnit)
                    WeatherDetailGrid(weather: weather)
                    Spacer(minLength: 40)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WeatherNow")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                if let w = weatherVM.weather {
                    Text(w.cityName)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            Spacer()
            UnitToggleButton(unit: $weatherVM.temperatureUnit)
            RefreshButton(isLoading: weatherVM.isLoading) {
                weatherVM.refresh(coordinate: locationManager.lastCoordinate)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }

    // MARK: - State Decision (pure logic, no UI)
    private enum ScreenState {
        case permissionDenied
        case locating
        case fetchingWeather
        case locationError(String)
        case weatherError(String)
        case success(WeatherModel)
    }

    private func decideState() -> ScreenState {
        if let locErr = locationManager.locationError {
            if locErr.isLocationPermissionError { return .permissionDenied }
            return .locationError(locErr.errorDescription ?? "Location error")
        }
        if locationManager.isLocating || !locationManager.isLocationAvailable {
            return .locating
        }
        if weatherVM.isLoading && weatherVM.weather == nil {
            return .fetchingWeather
        }
        if let weatherErr = weatherVM.errorMessage, weatherVM.weather == nil {
            return .weatherError(weatherErr)
        }
        if let weather = weatherVM.weather {
            return .success(weather)
        }
        return .fetchingWeather
    }
}

#Preview {
    WeatherView()
}

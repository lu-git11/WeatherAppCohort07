//
//  StateView.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/13/26.
//

import SwiftUI

// MARK: - Loading
struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.5)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 60)
    }
}

// MARK: - Error
struct ErrorView: View {
    let message:  String
    let canRetry: Bool
    var onRetry:  (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.multicolor)

            Text("Something went wrong")
                .font(.headline)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            if canRetry, let retry = onRetry {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 40)
    }
}

// MARK: - Permission Denied
struct PermissionDeniedView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.7))

            Text("Location Access Needed")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text("WeatherNow needs your location to show local weather. Please enable location access in Settings.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onRetry) {
                    Text("I've updated permissions")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 40)
    }
}

// MARK: - Refresh Button
struct RefreshButton: View {
    let isLoading: Bool
    let action:    () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(width: 36, height: 36)
        }
        .disabled(isLoading)
        .foregroundStyle(.white)
    }
}

// MARK: - Unit Toggle
struct UnitToggleButton: View {
    @Binding var unit: TemperatureUnit

    var body: some View {
        Button {
            unit = unit == .celsius ? .fahrenheit : .celsius
        } label: {
            Text(unit.label)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .frame(width: 44, height: 36)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
                .foregroundStyle(.white)
        }
        .padding(.trailing, 8)
    }
}

// MARK: - Background Gradient
struct BackgroundGradientView: View {
    let weatherCode: Int?

    var colors: [Color] {
        guard let code = weatherCode else {
            return [Color(red: 0.27, green: 0.5, blue: 0.88),
                    Color(red: 0.1,  green: 0.3, blue: 0.7)]
        }
        switch code {
        case 800:
            return [Color(red: 0.27, green: 0.65, blue: 1.0),
                    Color(red: 0.1,  green: 0.35, blue: 0.85)]
        case 801...802:
            return [Color(red: 0.5, green: 0.65, blue: 0.85),
                    Color(red: 0.3, green: 0.5,  blue: 0.75)]
        case 803...804:
            return [Color(red: 0.55, green: 0.6, blue: 0.7),
                    Color(red: 0.35, green: 0.4, blue: 0.55)]
        case 500...531, 300...321:
            return [Color(red: 0.3, green: 0.4, blue: 0.6),
                    Color(red: 0.15, green: 0.25, blue: 0.45)]
        case 600...622:
            return [Color(red: 0.7, green: 0.8, blue: 0.95),
                    Color(red: 0.5, green: 0.6, blue: 0.8)]
        case 200...232:
            return [Color(red: 0.2, green: 0.2, blue: 0.35),
                    Color(red: 0.1, green: 0.1, blue: 0.25)]
        default:
            return [Color(red: 0.27, green: 0.5, blue: 0.88),
                    Color(red: 0.1,  green: 0.3, blue: 0.7)]
        }
    }

    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.0), value: weatherCode)
    }
}

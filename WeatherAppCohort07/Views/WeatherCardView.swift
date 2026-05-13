//
//  WeatherCardView.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/13/26.
//

import SwiftUI
import CoreLocation
import _LocationEssentials

struct WeatherCardView: View {
    let weather: WeatherModel
    let unit:    TemperatureUnit

    var body: some View {
        VStack(spacing: 16) {
            // Condition icon
            Image(systemName: weather.conditionIcon)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 72, weight: .thin))
                .shadow(radius: 8)

            // Temperature
            Text(weather.formattedTemperature(unit: unit))
                .font(.system(size: 64, weight: .ultraLight, design: .rounded))
                .foregroundStyle(.white)

            // Condition
            Text(weather.condition)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))

            // Feels-like
            Text("Feels like \(weather.feelsLike.formatted(.number.precision(.fractionLength(1))))°")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            Divider().background(.white.opacity(0.3))

            // Coordinates
            Label(
                String(format: "%.4f°N  %.4f°E",
                       weather.coordinate.latitude,
                       weather.coordinate.longitude),
                systemImage: "location.fill"
            )
            .font(.caption)
            .foregroundStyle(.white.opacity(0.65))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Detail Grid
struct WeatherDetailGrid: View {
    let weather: WeatherModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            DetailCell(icon: "wind",            title: "Wind",       value: weather.formattedWindSpeed)
            DetailCell(icon: "humidity",        title: "Humidity",   value: "\(weather.humidity)%")
            DetailCell(icon: "eye",             title: "Visibility", value: String(format: "%.1f km", weather.visibility))
            DetailCell(icon: "clock",           title: "Updated",    value: weather.formattedFetchTime)
            DetailCell(icon: "safari",          title: "Direction",  value: cardinalDirection(weather.windDirection))
            DetailCell(icon: "thermometer.medium", title: "Feels Like",
                       value: String(format: "%.1f°", weather.feelsLike))
        }
    }

    private func cardinalDirection(_ degrees: Int) -> String {
        let dirs = ["N","NE","E","SE","S","SW","W","NW"]
        let index = Int((Double(degrees) + 22.5) / 45.0) % 8
        return dirs[index]
    }
}

struct DetailCell: View {
    let icon:  String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


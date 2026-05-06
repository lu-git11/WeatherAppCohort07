//
//  WeatherModel.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/5/26.
//

import Foundation


//API 1
struct GeocodingResult: Codable{
    let name: String
    let latitude: Double
    let longitude: Double
}

struct GeocodingResponse: Codable{
    let result:[GeocodingResult]?
    
}

//API 2

struct CurrentWeather: Codable{
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
    let time: String
}

struct ForecastResponse: Codable{
    let current_weather: CurrentWeather
}

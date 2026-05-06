//
//  WeatherService.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/5/26.
//


import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case badStatusCode(statusCode: Int)
    case noResults
}

class WeatherService{
    
    private func performGetRequest( url: URL ) async throws -> Data {
        
        //step 1 - create session
        let session: URLSession = URLSession.shared
        
        //step 2 - send GET request to URL and wait
        let result: (Data,URLResponse) = try await session.data(from: url)
        
        // step 3 - Split result into:
        //data: JSON
        //repsonse: information aout request
        let data: Data = result.0
        let response: URLResponse = result.1
        
        //step 4 - We want HTTP response so we can read the status code
        if let httpResponse: HTTPURLResponse = response as? HTTPURLResponse{
            // step 5 - get the status coe response
            let statusCode: Int = httpResponse.statusCode
            //step 6 - only treat 200-299 as success
            if statusCode < 200 || statusCode > 299{
                throw APIError.badStatusCode(statusCode: statusCode)
            }
            //step 7 - return in JSON format
            return data
        }
        
        throw APIError.invalidResponse
    }
    
    private func fetchCoordinates(city: String) async throws -> GeocodingResult {
        
        var urlComponents: URLComponents? = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")
        if(urlComponents == nil){
            throw APIError.invalidURL
        }
        
        urlComponents?.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]
        
        let url:URL? = urlComponents?.url
        
        if url == nil{
            throw APIError.invalidURL
        }
        let data : Data = try await performGetRequest(url: url!)
        
        let decoder:JSONDecoder = JSONDecoder()
        
        let response: GeocodingResponse = try decoder.decode(GeocodingResponse.self, from: data)
        
        if let results:[GeocodingResult] = response.result{
            if let firstResult:GeocodingResult = results.first{
                return firstResult
            }
        }
        throw APIError.noResults
    }
    private func fetchWeather(latitude: Double, longitude: Double) async throws -> CurrentWeather{
        var urlComponents = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        
        if(urlComponents == nil){
            throw APIError.invalidURL
        }
        
        urlComponents?.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current_weather", value: "true"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        
        let url:URL? = urlComponents?.url
        
        if url == nil{
            throw APIError.invalidURL
        }
        
        let data: Data = try await performGetRequest(url: url!)
        let decoder: JSONDecoder = JSONDecoder()
        let repsonse: ForecastResponse = try decoder.decode( ForecastResponse.self, from:data)
        
        return repsonse.current_weather
    }
    
    func fetchCurrentWeather(cityName:String) async throws -> (city:String, weather:CurrentWeather) {
        let geoResult = try await fetchCoordinates(city: cityName)
        let currentWeather = try await fetchWeather(latitude: geoResult.latitude, longitude: geoResult.longitude)
        
        return (geoResult.name, currentWeather)
    }
}

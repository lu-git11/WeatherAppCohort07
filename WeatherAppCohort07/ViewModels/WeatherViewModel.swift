//
//  WeatherViewModel.swift
//  WeatherAppCohort07
//
//  Created by jeffrey lullen on 5/5/26.
//

import Foundation
import Combine

@MainActor
class WeatherViewModel:ObservableObject{
    
    @Published var searchText:String = ""
    @Published var cityName:String = ""
    @Published var tempText:String = ""
    @Published var windText:String = ""
    @Published var timeText:String = ""
    @Published var isLoading:Bool = false
    @Published var errorMessage:String = ""
    
    private let weatherService = WeatherService()
    
    func searchWeather() async {
        self.errorMessage = ""
        self.isLoading = true
        
        let trimmedText: String = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedText.isEmpty{
            self.errorMessage = "Please search city "
            self.isLoading = false
        }
        do {
            let result = try await weatherService.fetchCurrentWeather(cityName: trimmedText)
            self.cityName = result.city
            self.tempText = "Temperature \(result.weather.temperature) celsius"
            self.windText = "Wind: \(result.weather.windspeed) km/h"
            self.timeText = "Time \(result.weather.time)"
            self.isLoading = false
        } catch {
            self.errorMessage = "Something wrong"
            self.isLoading = false
            
        }
    }
}

import Foundation
import CoreLocation

actor WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1"
    private let airQualityURL = "https://air-quality-api.open-meteo.com/v1/air-quality"
    private let marineURL = "https://marine-api.open-meteo.com/v1/marine"
    private let floodURL = "https://flood-api.open-meteo.com/v1/flood"
    private let geocodeURL = "https://geocoding-api.open-meteo.com/v1/search"
    private let elevationURL = "https://api.open-meteo.com/v1/elevation"
    private let historicalURL = "https://archive-api.open-meteo.com/v1/archive"
    private let session = URLSession.shared

    // MARK: - Current Weather + Forecast
    func fetchForecast(lat: Double, lon: Double) async throws -> WeatherResponse {
        var components = URLComponents(string: "\(baseURL)/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,cloud_cover,pressure_msl,surface_pressure,visibility,uv_index"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation,cloud_cover,wind_speed_10m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code,sunrise,sunset,wind_speed_10m_max,uv_index_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }

    // MARK: - Quick Current Weather for Map Pin
    func fetchCurrentWeather(lat: Double, lon: Double, city: String) async throws -> WeatherPin {
        var components = URLComponents(string: "\(baseURL)/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(WeatherResponse.self, from: data)

        return WeatherPin(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            temperature: response.current?.temperature2m ?? 0,
            weatherCode: response.current?.weatherCode ?? 0,
            city: city,
            humidity: response.current?.relativeHumidity2m,
            windSpeed: response.current?.windSpeed10m,
            aqi: nil
        )
    }

    // MARK: - Air Quality
    func fetchAirQuality(lat: Double, lon: Double) async throws -> AirQualityResponse {
        var components = URLComponents(string: airQualityURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "hourly", value: "pm2_5,pm10,us_aqi,uv_index,nitrogen_dioxide,ozone"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        return try JSONDecoder().decode(AirQualityResponse.self, from: data)
    }

    // MARK: - Marine Forecast
    func fetchMarine(lat: Double, lon: Double) async throws -> MarineResponse {
        var components = URLComponents(string: marineURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "hourly", value: "wave_height,wave_period,wave_direction,ocean_current_velocity"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        return try JSONDecoder().decode(MarineResponse.self, from: data)
    }

    // MARK: - Flood Data
    func fetchFlood(lat: Double, lon: Double) async throws -> FloodResponse {
        var components = URLComponents(string: floodURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "daily", value: "river_discharge"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        return try JSONDecoder().decode(FloodResponse.self, from: data)
    }

    // MARK: - Geocoding
    func searchCity(_ query: String) async throws -> [GeocodingResult] {
        var components = URLComponents(string: geocodeURL)!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
        return response.results ?? []
    }

    // MARK: - Elevation
    func fetchElevation(lat: Double, lon: Double) async throws -> Double {
        var components = URLComponents(string: elevationURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(ElevationResponse.self, from: data)
        return response.elevation.first ?? 0
    }

    // MARK: - Historical Weather
    func fetchHistorical(lat: Double, lon: Double, startDate: String, endDate: String) async throws -> WeatherResponse {
        var components = URLComponents(string: historicalURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(lat)"),
            URLQueryItem(name: "longitude", value: "\(lon)"),
            URLQueryItem(name: "start_date", value: startDate),
            URLQueryItem(name: "end_date", value: endDate),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation,wind_speed_10m"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        return try JSONDecoder().decode(WeatherResponse.self, from: data)
    }
}

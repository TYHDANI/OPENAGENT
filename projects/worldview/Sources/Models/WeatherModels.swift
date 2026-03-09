import Foundation
import CoreLocation

// MARK: - Open-Meteo Weather
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String?
    let current: CurrentWeather?
    let hourly: HourlyWeather?
    let daily: DailyWeather?
}

struct CurrentWeather: Codable {
    let time: String
    let temperature2m: Double?
    let relativeHumidity2m: Int?
    let apparentTemperature: Double?
    let weatherCode: Int?
    let windSpeed10m: Double?
    let windDirection10m: Int?
    let windGusts10m: Double?
    let precipitation: Double?
    let cloudCover: Int?
    let pressureMsl: Double?
    let surfacePressure: Double?
    let visibility: Double?
    let uvIndex: Double?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
        case windGusts10m = "wind_gusts_10m"
        case precipitation
        case cloudCover = "cloud_cover"
        case pressureMsl = "pressure_msl"
        case surfacePressure = "surface_pressure"
        case visibility
        case uvIndex = "uv_index"
    }
}

struct HourlyWeather: Codable {
    let time: [String]
    let temperature2m: [Double?]?
    let precipitation: [Double?]?
    let cloudCover: [Int?]?
    let windSpeed10m: [Double?]?
    let weatherCode: [Int?]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case precipitation
        case cloudCover = "cloud_cover"
        case windSpeed10m = "wind_speed_10m"
        case weatherCode = "weather_code"
    }
}

struct DailyWeather: Codable {
    let time: [String]
    let temperature2mMax: [Double?]?
    let temperature2mMin: [Double?]?
    let precipitationSum: [Double?]?
    let weatherCode: [Int?]?
    let sunrise: [String?]?
    let sunset: [String?]?
    let windSpeed10mMax: [Double?]?
    let uvIndexMax: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationSum = "precipitation_sum"
        case weatherCode = "weather_code"
        case sunrise, sunset
        case windSpeed10mMax = "wind_speed_10m_max"
        case uvIndexMax = "uv_index_max"
    }
}

// MARK: - Air Quality (Open-Meteo)
struct AirQualityResponse: Codable {
    let latitude: Double
    let longitude: Double
    let hourly: AirQualityHourly?
}

struct AirQualityHourly: Codable {
    let time: [String]
    let pm25: [Double?]?
    let pm10: [Double?]?
    let usAqi: [Int?]?
    let uvIndex: [Double?]?
    let nitrogenDioxide: [Double?]?
    let ozone: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case pm25 = "pm2_5"
        case pm10
        case usAqi = "us_aqi"
        case uvIndex = "uv_index"
        case nitrogenDioxide = "nitrogen_dioxide"
        case ozone
    }
}

// MARK: - Marine (Open-Meteo)
struct MarineResponse: Codable {
    let latitude: Double
    let longitude: Double
    let hourly: MarineHourly?
}

struct MarineHourly: Codable {
    let time: [String]
    let waveHeight: [Double?]?
    let wavePeriod: [Double?]?
    let waveDirection: [Int?]?
    let oceanCurrentVelocity: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case waveHeight = "wave_height"
        case wavePeriod = "wave_period"
        case waveDirection = "wave_direction"
        case oceanCurrentVelocity = "ocean_current_velocity"
    }
}

// MARK: - Flood (Open-Meteo)
struct FloodResponse: Codable {
    let latitude: Double
    let longitude: Double
    let daily: FloodDaily?
}

struct FloodDaily: Codable {
    let time: [String]
    let riverDischarge: [Double?]?

    enum CodingKeys: String, CodingKey {
        case time
        case riverDischarge = "river_discharge"
    }
}

// MARK: - Geocoding (Open-Meteo)
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let countryCode: String?
    let admin1: String?
    let population: Int?
    let elevation: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, country
        case countryCode = "country_code"
        case admin1, population, elevation
    }
}

// MARK: - RainViewer Weather Radar
struct RainViewerResponse: Codable {
    let version: String
    let generated: Int
    let host: String
    let radar: RainViewerRadar
}

struct RainViewerRadar: Codable {
    let past: [RainViewerFrame]
    let nowcast: [RainViewerFrame]?
}

struct RainViewerFrame: Codable, Identifiable {
    let time: Int
    let path: String

    var id: Int { time }
    var date: Date { Date(timeIntervalSince1970: TimeInterval(time)) }
}

// MARK: - Weather Code Mapping
struct WeatherCondition {
    let code: Int
    let description: String
    let icon: String

    static func from(code: Int) -> WeatherCondition {
        switch code {
        case 0: return WeatherCondition(code: 0, description: "Clear sky", icon: "sun.max.fill")
        case 1: return WeatherCondition(code: 1, description: "Mainly clear", icon: "sun.min.fill")
        case 2: return WeatherCondition(code: 2, description: "Partly cloudy", icon: "cloud.sun.fill")
        case 3: return WeatherCondition(code: 3, description: "Overcast", icon: "cloud.fill")
        case 45, 48: return WeatherCondition(code: code, description: "Fog", icon: "cloud.fog.fill")
        case 51, 53, 55: return WeatherCondition(code: code, description: "Drizzle", icon: "cloud.drizzle.fill")
        case 61, 63, 65: return WeatherCondition(code: code, description: "Rain", icon: "cloud.rain.fill")
        case 66, 67: return WeatherCondition(code: code, description: "Freezing Rain", icon: "cloud.sleet.fill")
        case 71, 73, 75: return WeatherCondition(code: code, description: "Snowfall", icon: "cloud.snow.fill")
        case 77: return WeatherCondition(code: code, description: "Snow grains", icon: "snowflake")
        case 80, 81, 82: return WeatherCondition(code: code, description: "Rain showers", icon: "cloud.heavyrain.fill")
        case 85, 86: return WeatherCondition(code: code, description: "Snow showers", icon: "cloud.snow.fill")
        case 95: return WeatherCondition(code: code, description: "Thunderstorm", icon: "cloud.bolt.fill")
        case 96, 99: return WeatherCondition(code: code, description: "Thunderstorm w/ hail", icon: "cloud.bolt.rain.fill")
        default: return WeatherCondition(code: code, description: "Unknown", icon: "questionmark.circle")
        }
    }
}

// MARK: - Weather Pin for Map
struct WeatherPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let temperature: Double
    let weatherCode: Int
    let city: String
    let humidity: Int?
    let windSpeed: Double?
    let aqi: Int?
}

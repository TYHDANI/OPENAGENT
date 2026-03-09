import Testing
@testable import Nighteye

@Test func testWeatherConditionMapping() {
    let clear = WeatherCondition.from(code: 0)
    #expect(clear.description == "Clear sky")
    #expect(clear.icon == "sun.max.fill")

    let rain = WeatherCondition.from(code: 63)
    #expect(rain.description == "Rain")

    let thunder = WeatherCondition.from(code: 95)
    #expect(thunder.description == "Thunderstorm")
}

@Test func testThreatLevelOrdering() {
    #expect(ThreatLevel.low < ThreatLevel.severe)
    #expect(ThreatLevel.elevated < ThreatLevel.high)
}

@Test func testDataLayerCategories() {
    #expect(DataLayerType.earthquakes.category == .naturalHazards)
    #expect(DataLayerType.weather.category == .weatherClimate)
    #expect(DataLayerType.satellites.category == .space)
    #expect(DataLayerType.maxarImagery.category == .satelliteImagery)
    #expect(DataLayerType.liveTVNews.category == .media)
}

@Test func testSatelliteGroupProperties() {
    let stations = SatelliteGroup.stations
    #expect(stations.displayName == "Space Stations")
    #expect(!stations.color.isEmpty)
}

@Test func testMaxarEventType() {
    let earthquake = MaxarEvent(id: "test-earthquake-2023", title: "Morocco Earthquake 2023", description: nil, bbox: [-9.5, 30.5, -7.5, 32.5], links: nil)
    #expect(earthquake.eventType == "Earthquake")
    #expect(earthquake.coordinate != nil)

    let hurricane = MaxarEvent(id: "test-hurricane", title: "Hurricane Ian", description: nil, bbox: nil, links: nil)
    #expect(hurricane.eventType == "Hurricane")
    #expect(hurricane.coordinate == nil)
}

@Test func testRegionPresets() {
    for region in RegionPreset.allCases {
        #expect(region.center.latitude != 0 || region.id == "Global")
        #expect(region.span.latitudeDelta > 0)
    }
}

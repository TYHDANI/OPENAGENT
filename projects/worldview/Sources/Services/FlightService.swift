import Foundation
import CoreLocation

actor FlightService {
    private let baseURL = "https://opensky-network.org/api/states/all"
    private let session = URLSession.shared

    private let militaryCallsigns = Set([
        "RCH", "REACH", "FORTE", "JAKE", "HOMER", "DOOM", "GHOST", "EVIL",
        "TOPCAT", "WRATH", "REAPER", "HAVOC", "COBRA", "KNIFE", "NUKE",
        "MAGIC", "BLOOD", "SKULL", "BONE", "IRON", "STEEL", "VIPER",
        "HAWK", "EAGLE", "WOLF", "BEAR", "TIGER", "LION", "STORM",
        "FURY", "BLADE", "SHADOW", "DARK", "NIGHT", "DEATH", "CHAOS",
        "RRR", "NAF", "IAM", "BAF", "GAF", "FAF", "RAF", "PAF",
        "USAF", "NAVY", "ARMY", "TANKER", "AWACS", "SIGINT"
    ])

    func fetchAll() async throws -> [FlightPin] {
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(OpenSkyResponse.self, from: data)

        guard let states = response.states else { return [] }

        return states.compactMap { state -> FlightPin? in
            guard state.count >= 17 else { return nil }

            let icao24 = state[0].stringValue ?? ""
            let callsign = state[1].stringValue?.trimmingCharacters(in: .whitespaces)
            let origin = state[2].stringValue ?? ""
            let lon = state[5].doubleValue
            let lat = state[6].doubleValue
            let altitude = state[7].doubleValue ?? state[13].doubleValue ?? 0
            let velocity = state[9].doubleValue ?? 0
            let heading = state[10].doubleValue ?? 0
            let vertRate = state[11].doubleValue ?? 0
            let onGround = state[8].boolValue ?? false

            guard let latitude = lat, let longitude = lon else { return nil }

            let isMilitary = checkMilitary(callsign: callsign, origin: origin)

            return FlightPin(
                id: icao24,
                callsign: callsign,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                altitude: altitude,
                velocity: velocity,
                heading: heading,
                verticalRate: vertRate,
                onGround: onGround,
                originCountry: origin,
                isMilitary: isMilitary
            )
        }
    }

    private func checkMilitary(callsign: String?, origin: String) -> Bool {
        guard let cs = callsign?.uppercased() else { return false }
        for prefix in militaryCallsigns {
            if cs.hasPrefix(prefix) { return true }
        }
        return false
    }
}

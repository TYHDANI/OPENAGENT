import Foundation

enum SampleData {
    static let homeID = UUID()
    static let officeID = UUID()
    static let bedroomID = UUID()
    static let livingRoomID = UUID()
    static let kitchenID = UUID()
    static let officeRoomID = UUID()
    static let confRoomID = UUID()
    static let lobbyID = UUID()

    static let properties: [Property] = [
        Property(id: homeID, name: "My Home", address: "123 Main St", type: .home, rooms: [
            Room(id: bedroomID, propertyID: homeID, name: "Master Bedroom", type: .bedroom, hasFilter: true),
            Room(id: livingRoomID, propertyID: homeID, name: "Living Room", type: .livingRoom, hasFilter: true),
            Room(id: kitchenID, propertyID: homeID, name: "Kitchen", type: .kitchen)
        ]),
        Property(id: officeID, name: "Downtown Office", address: "456 Business Ave", type: .office, rooms: [
            Room(id: officeRoomID, propertyID: officeID, name: "Open Office", type: .office, hasFilter: true),
            Room(id: confRoomID, propertyID: officeID, name: "Conference Room", type: .office),
            Room(id: lobbyID, propertyID: officeID, name: "Lobby", type: .livingRoom)
        ], isFleetProperty: true)
    ]

    static let readings: [AirReading] = {
        var result: [AirReading] = []
        let rooms = [bedroomID, livingRoomID, kitchenID, officeRoomID, confRoomID, lobbyID]
        for roomID in rooms {
            // Generate 24 hours of hourly readings
            for h in 0..<24 {
                let pm25 = Double.random(in: 3...25)
                let pm10 = Double.random(in: 5...40)
                let co2 = Double.random(in: 400...900)
                let voc = Double.random(in: 50...350)
                let temp = Double.random(in: 68...76)
                let humidity = Double.random(in: 35...55)
                var reading = AirReading(roomID: roomID, pm25: pm25, pm10: pm10, co2: co2,
                                        voc: voc, temperature: temp, humidity: humidity)
                reading.timestamp = Calendar.current.date(byAdding: .hour, value: -h, to: Date()) ?? Date()
                result.append(reading)
            }
        }
        return result
    }()
}

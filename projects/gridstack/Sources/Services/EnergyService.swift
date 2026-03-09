import Foundation
import SwiftUI

@Observable
final class EnergyService {
    var energyReadings: [EnergyReading] = []
    var demandResponseEvents: [DemandResponseEvent] = []
    var miningSessions: [MiningSession] = []
    var earningsRecords: [EarningsRecord] = []
    var prosumerProfile: ProsumerProfile = .default

    // MARK: - Computed Properties

    var totalEarnings: Double {
        earningsRecords.reduce(0) { $0 + $1.amount }
    }

    var todayEarnings: Double {
        earnings(for: .day)
    }

    var weekEarnings: Double {
        earnings(for: .week)
    }

    var monthEarnings: Double {
        earnings(for: .month)
    }

    var todayUsageKWh: Double {
        readingsForPeriod(.day).reduce(0) { $0 + $1.consumptionKWh }
    }

    var todayCostUSD: Double {
        readingsForPeriod(.day).reduce(0) { $0 + $1.costUSD }
    }

    var weekUsageKWh: Double {
        readingsForPeriod(.week).reduce(0) { $0 + $1.consumptionKWh }
    }

    var activeMiningSessions: [MiningSession] {
        miningSessions.filter { $0.isActive }
    }

    var totalHashRateTHs: Double {
        activeMiningSessions.reduce(0) { $0 + $1.hashRateTHs }
    }

    var totalHeatReclaimedBTU: Double {
        miningSessions.filter { $0.heatReclaimed }.reduce(0) { $0 + $1.heatOutputBTU }
    }

    var totalHeatSavingsUSD: Double {
        miningSessions.reduce(0) { $0 + $1.heatReclaimSavingsUSD }
    }

    var totalMiningRevenueUSD: Double {
        miningSessions.reduce(0) { $0 + $1.btcEarned } * 60_000
    }

    var totalMiningCostUSD: Double {
        miningSessions.reduce(0) { $0 + $1.electricityCostUSD }
    }

    var miningNetProfitUSD: Double {
        totalMiningRevenueUSD - totalMiningCostUSD + totalHeatSavingsUSD
    }

    var completedDREvents: [DemandResponseEvent] {
        demandResponseEvents.filter { $0.status == .completed }
    }

    var upcomingDREvents: [DemandResponseEvent] {
        demandResponseEvents.filter { $0.status == .upcoming }
    }

    var activeDREvents: [DemandResponseEvent] {
        demandResponseEvents.filter { $0.status == .active }
    }

    var totalDREarnings: Double {
        completedDREvents.reduce(0) { $0 + $1.earningsUSD }
    }

    var certificationProgress: Double {
        let total = prosumerProfile.certifications.count
        guard total > 0 else { return 0 }
        let completed = prosumerProfile.certifications.filter { $0.isCompleted }.count
        return Double(completed) / Double(total)
    }

    // MARK: - Initialization

    init() {
        loadSampleData()
    }

    // MARK: - Period Filtering

    func earnings(for period: TimePeriod) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch period {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return earningsRecords
            .filter { $0.date >= startDate }
            .reduce(0) { $0 + $1.amount }
    }

    func earningsBySource(for period: TimePeriod) -> [EarningsRecord.EarningsSource: Double] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch period {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        let filtered = earningsRecords.filter { $0.date >= startDate }
        var result: [EarningsRecord.EarningsSource: Double] = [:]
        for record in filtered {
            result[record.source, default: 0] += record.amount
        }
        return result
    }

    func readingsForPeriod(_ period: TimePeriod) -> [EnergyReading] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch period {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return energyReadings.filter { $0.timestamp >= startDate }
    }

    func dailyUsage(for days: Int) -> [(date: Date, kWh: Double, cost: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var results: [(date: Date, kWh: Double, cost: Double)] = []

        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let dayReadings = energyReadings.filter {
                $0.timestamp >= dayStart && $0.timestamp < dayEnd
            }
            let totalKWh = dayReadings.reduce(0) { $0 + $1.consumptionKWh }
            let totalCost = dayReadings.reduce(0) { $0 + $1.costUSD }
            results.append((date: dayStart, kWh: totalKWh, cost: totalCost))
        }
        return results
    }

    func dailyEarnings(for days: Int) -> [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var results: [(date: Date, amount: Double)] = []

        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let dayEarnings = earningsRecords.filter {
                $0.date >= dayStart && $0.date < dayEnd
            }
            let total = dayEarnings.reduce(0) { $0 + $1.amount }
            results.append((date: dayStart, amount: total))
        }
        return results
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        let calendar = Calendar.current
        let now = Date()

        // Generate 30 days of energy readings (4 per day = hourly averages at 6AM, 12PM, 6PM, 12AM)
        for dayOffset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)

            let hours = [6, 12, 18, 0]
            for hour in hours {
                guard let timestamp = calendar.date(byAdding: .hour, value: hour, to: dayStart) else { continue }
                let baseUsage = Double.random(in: 4.0...9.0)
                let rate = prosumerProfile.electricityRatePerKWh
                energyReadings.append(
                    EnergyReading(
                        timestamp: timestamp,
                        consumptionKWh: baseUsage,
                        generationKWh: hour >= 6 && hour <= 18 ? Double.random(in: 0...2.0) : 0,
                        costUSD: baseUsage * rate,
                        source: .grid
                    )
                )
            }
        }

        // Demand Response Events
        let programs = ["Nest Rush Hour Rewards", "PG&E SmartAC", "OhmConnect", "SCE Summer Savings"]
        let eventTypes: [DemandResponseEvent.DREventType] = [.thermostatAdjust, .loadShift, .batteryDispatch]

        // Past completed events
        for i in 0..<12 {
            guard let eventDate = calendar.date(byAdding: .day, value: -(i * 3 + 1), to: now) else { continue }
            let program = programs[i % programs.count]
            let duration = [60, 120, 90, 180][i % 4]
            demandResponseEvents.append(
                DemandResponseEvent(
                    programName: program,
                    eventDate: eventDate,
                    durationMinutes: duration,
                    status: .completed,
                    earningsUSD: Double.random(in: 2.0...18.0),
                    kWhReduced: Double.random(in: 1.5...6.0),
                    eventType: eventTypes[i % eventTypes.count]
                )
            )
        }

        // Active event
        demandResponseEvents.append(
            DemandResponseEvent(
                programName: "PG&E SmartAC",
                eventDate: calendar.date(byAdding: .hour, value: -1, to: now) ?? now,
                durationMinutes: 120,
                status: .active,
                earningsUSD: 8.50,
                kWhReduced: 3.2,
                eventType: .thermostatAdjust
            )
        )

        // Upcoming events
        for i in 0..<3 {
            guard let eventDate = calendar.date(byAdding: .day, value: i + 1, to: now) else { continue }
            demandResponseEvents.append(
                DemandResponseEvent(
                    programName: programs[i % programs.count],
                    eventDate: eventDate,
                    durationMinutes: [90, 120, 60][i],
                    status: .upcoming,
                    earningsUSD: Double.random(in: 4.0...12.0),
                    kWhReduced: 0,
                    eventType: eventTypes[i % eventTypes.count]
                )
            )
        }

        // Mining Sessions
        for i in 0..<15 {
            guard let start = calendar.date(byAdding: .day, value: -(i * 2), to: now),
                  let end = calendar.date(byAdding: .hour, value: Int.random(in: 8...24), to: start) else { continue }

            let power = Double.random(in: 800...1500)
            let hours = end.timeIntervalSince(start) / 3600
            let kWh = (power / 1000.0) * hours
            let cost = kWh * prosumerProfile.electricityRatePerKWh

            miningSessions.append(
                MiningSession(
                    startTime: start,
                    endTime: i == 0 ? nil : end,
                    hashRateTHs: Double.random(in: 20...45),
                    powerConsumptionW: power,
                    btcEarned: Double.random(in: 0.00002...0.00015),
                    electricityCostUSD: cost,
                    heatOutputBTU: power * 3.412 * hours,
                    heatReclaimed: Bool.random() || i < 5,
                    algorithm: .sha256
                )
            )
        }

        // Earnings Records (30 days)
        for dayOffset in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }

            // DR earnings (not every day)
            if dayOffset % 3 == 0 {
                earningsRecords.append(
                    EarningsRecord(
                        date: date,
                        amount: Double.random(in: 2.0...15.0),
                        source: .demandResponse,
                        description: "DR event participation"
                    )
                )
            }

            // Mining earnings (most days)
            if dayOffset % 2 == 0 {
                earningsRecords.append(
                    EarningsRecord(
                        date: date,
                        amount: Double.random(in: 1.50...8.00),
                        source: .mining,
                        description: "BTC mining yield"
                    )
                )
            }

            // Heat reclamation savings (winter months)
            if dayOffset % 4 == 0 {
                earningsRecords.append(
                    EarningsRecord(
                        date: date,
                        amount: Double.random(in: 0.50...3.00),
                        source: .heatReclamation,
                        description: "Heat reclaim offset"
                    )
                )
            }

            // TOU savings
            if dayOffset % 5 == 0 {
                earningsRecords.append(
                    EarningsRecord(
                        date: date,
                        amount: Double.random(in: 0.80...4.00),
                        source: .touSavings,
                        description: "Off-peak usage savings"
                    )
                )
            }
        }
    }
}

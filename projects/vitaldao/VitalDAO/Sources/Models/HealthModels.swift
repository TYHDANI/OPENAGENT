import Foundation

// MARK: - HealthScore

struct HealthScore: Identifiable, Sendable {
    let id = UUID()
    let overall: Int
    let sleep: Int
    let activity: Int
    let recovery: Int
    let heart: Int
    let date: Date
    let breakdown: [ScoreComponent]

    var overallNormalized: Double { Double(overall) / 100.0 }

    struct ScoreComponent: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let score: Int
        let weight: Double
        let icon: String
    }

    static let mock = HealthScore(
        overall: 82,
        sleep: 78,
        activity: 85,
        recovery: 79,
        heart: 88,
        date: .now,
        breakdown: [
            ScoreComponent(name: "Sleep Quality", score: 78, weight: 0.25, icon: "moon.fill"),
            ScoreComponent(name: "Activity", score: 85, weight: 0.25, icon: "figure.run"),
            ScoreComponent(name: "Recovery", score: 79, weight: 0.20, icon: "arrow.counterclockwise.heart"),
            ScoreComponent(name: "Heart Health", score: 88, weight: 0.15, icon: "heart.fill"),
            ScoreComponent(name: "Consistency", score: 82, weight: 0.15, icon: "chart.line.uptrend.xyaxis"),
        ]
    )
}


// MARK: - SleepData

struct SleepData: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let totalHours: Double
    let deepHours: Double
    let remHours: Double
    let lightHours: Double
    let awakeHours: Double
    let score: Int
    let efficiency: Double
    let latencyMinutes: Int
    let heartRateAvg: Int
    let hrvAvg: Int
    let respiratoryRate: Double

    var qualityLabel: String {
        switch score {
        case 85...100: return "Excellent"
        case 70..<85: return "Good"
        case 55..<70: return "Fair"
        default: return "Poor"
        }
    }

    static let mockWeek: [SleepData] = {
        let calendar = Calendar.current
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
            let totalHours = Double.random(in: 6.2...8.5)
            let deepPct = Double.random(in: 0.15...0.25)
            let remPct = Double.random(in: 0.18...0.28)
            let awakePct = Double.random(in: 0.03...0.08)
            let lightPct = 1.0 - deepPct - remPct - awakePct

            return SleepData(
                date: date,
                totalHours: totalHours,
                deepHours: totalHours * deepPct,
                remHours: totalHours * remPct,
                lightHours: totalHours * lightPct,
                awakeHours: totalHours * awakePct,
                score: Int.random(in: 62...95),
                efficiency: Double.random(in: 0.82...0.97),
                latencyMinutes: Int.random(in: 5...25),
                heartRateAvg: Int.random(in: 52...64),
                hrvAvg: Int.random(in: 38...72),
                respiratoryRate: Double.random(in: 14.0...17.0)
            )
        }
    }()
}


// MARK: - ActivityData

struct ActivityData: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let steps: Int
    let activeCalories: Int
    let totalCalories: Int
    let distanceKm: Double
    let activeMinutes: Int
    let standingHours: Int
    let vo2Max: Double?
    let trainingLoad: Double?
    let workouts: [Workout]

    var stepsFormatted: String {
        if steps >= 1000 {
            return String(format: "%.1fK", Double(steps) / 1000.0)
        }
        return "\(steps)"
    }

    struct Workout: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let type: WorkoutType
        let durationMinutes: Int
        let calories: Int
        let heartRateAvg: Int
        let heartRateMax: Int
        let date: Date

        enum WorkoutType: String, CaseIterable, Sendable {
            case running = "Running"
            case cycling = "Cycling"
            case swimming = "Swimming"
            case strength = "Strength"
            case hiit = "HIIT"
            case yoga = "Yoga"
            case walking = "Walking"

            var icon: String {
                switch self {
                case .running: return "figure.run"
                case .cycling: return "figure.outdoor.cycle"
                case .swimming: return "figure.pool.swim"
                case .strength: return "dumbbell.fill"
                case .hiit: return "flame.fill"
                case .yoga: return "figure.mind.and.body"
                case .walking: return "figure.walk"
                }
            }
        }
    }

    static let mockWeek: [ActivityData] = {
        let calendar = Calendar.current
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
            let steps = Int.random(in: 4200...14800)
            let workoutTypes: [Workout.WorkoutType] = [.running, .cycling, .strength, .hiit, .yoga]
            let todayWorkouts = (0..<Int.random(in: 0...2)).map { _ in
                let wType = workoutTypes.randomElement() ?? .running
                return Workout(
                    name: wType.rawValue,
                    type: wType,
                    durationMinutes: Int.random(in: 25...75),
                    calories: Int.random(in: 150...600),
                    heartRateAvg: Int.random(in: 120...155),
                    heartRateMax: Int.random(in: 160...185),
                    date: date
                )
            }
            return ActivityData(
                date: date,
                steps: steps,
                activeCalories: Int.random(in: 280...720),
                totalCalories: Int.random(in: 1800...2800),
                distanceKm: Double(steps) * 0.0008,
                activeMinutes: Int.random(in: 30...120),
                standingHours: Int.random(in: 6...12),
                vo2Max: Double.random(in: 42.0...52.0),
                trainingLoad: Double.random(in: 20.0...85.0),
                workouts: todayWorkouts
            )
        }
    }()
}


// MARK: - RecoveryData

struct RecoveryData: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let score: Int
    let hrv: Int
    let restingHeartRate: Int
    let bodyTemperatureDelta: Double
    let spo2: Double
    let respiratoryRate: Double
    let readiness: ReadinessLevel

    enum ReadinessLevel: String, Sendable {
        case peak = "Peak"
        case good = "Good"
        case moderate = "Moderate"
        case low = "Low"

        var color: String {
            switch self {
            case .peak: return "successGreen"
            case .good: return "accentTeal"
            case .moderate: return "warningAmber"
            case .low: return "heartRed"
            }
        }
    }

    static let mockWeek: [RecoveryData] = {
        let calendar = Calendar.current
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
            let score = Int.random(in: 45...98)
            let readiness: ReadinessLevel = {
                switch score {
                case 85...100: return .peak
                case 70..<85: return .good
                case 55..<70: return .moderate
                default: return .low
                }
            }()
            return RecoveryData(
                date: date,
                score: score,
                hrv: Int.random(in: 35...78),
                restingHeartRate: Int.random(in: 48...65),
                bodyTemperatureDelta: Double.random(in: -0.3...0.5),
                spo2: Double.random(in: 95.0...99.5),
                respiratoryRate: Double.random(in: 13.5...17.5),
                readiness: readiness
            )
        }
    }()
}


// MARK: - BloodWork

struct BloodWork: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let labName: String
    let markers: [BioMarker]

    struct BioMarker: Identifiable, Sendable {
        let id = UUID()
        let name: String
        let value: Double
        let unit: String
        let referenceRange: ClosedRange<Double>
        let category: Category

        var isInRange: Bool {
            referenceRange.contains(value)
        }

        var statusLabel: String {
            if value < referenceRange.lowerBound { return "Low" }
            if value > referenceRange.upperBound { return "High" }
            return "Normal"
        }

        enum Category: String, CaseIterable, Sendable {
            case metabolic = "Metabolic"
            case lipids = "Lipids"
            case hormones = "Hormones"
            case inflammation = "Inflammation"
            case vitamins = "Vitamins"
            case thyroid = "Thyroid"
            case blood = "Blood Count"
        }
    }

    static let mock = BloodWork(
        date: Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now,
        labName: "Quest Diagnostics",
        markers: [
            BioMarker(name: "Glucose (Fasting)", value: 92, unit: "mg/dL", referenceRange: 70...100, category: .metabolic),
            BioMarker(name: "HbA1c", value: 5.2, unit: "%", referenceRange: 4.0...5.6, category: .metabolic),
            BioMarker(name: "Total Cholesterol", value: 185, unit: "mg/dL", referenceRange: 125...200, category: .lipids),
            BioMarker(name: "LDL", value: 105, unit: "mg/dL", referenceRange: 0...100, category: .lipids),
            BioMarker(name: "HDL", value: 62, unit: "mg/dL", referenceRange: 40...100, category: .lipids),
            BioMarker(name: "Triglycerides", value: 88, unit: "mg/dL", referenceRange: 0...150, category: .lipids),
            BioMarker(name: "Testosterone", value: 620, unit: "ng/dL", referenceRange: 300...1000, category: .hormones),
            BioMarker(name: "Cortisol (AM)", value: 14.2, unit: "mcg/dL", referenceRange: 6.0...18.4, category: .hormones),
            BioMarker(name: "hs-CRP", value: 0.8, unit: "mg/L", referenceRange: 0...3.0, category: .inflammation),
            BioMarker(name: "Vitamin D", value: 48, unit: "ng/mL", referenceRange: 30...100, category: .vitamins),
            BioMarker(name: "B12", value: 680, unit: "pg/mL", referenceRange: 200...1100, category: .vitamins),
            BioMarker(name: "Ferritin", value: 85, unit: "ng/mL", referenceRange: 30...400, category: .blood),
            BioMarker(name: "TSH", value: 2.1, unit: "mIU/L", referenceRange: 0.4...4.0, category: .thyroid),
        ]
    )
}


// MARK: - Weekly Trend Point

struct TrendPoint: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String

    static func mockWeekly(baseValue: Double, variance: Double, label: String) -> [TrendPoint] {
        let calendar = Calendar.current
        return (0..<7).reversed().map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now) ?? .now
            let value = baseValue + Double.random(in: -variance...variance)
            return TrendPoint(date: date, value: value, label: label)
        }
    }
}

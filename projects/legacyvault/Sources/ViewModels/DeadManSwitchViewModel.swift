import Foundation

@Observable
final class DeadManSwitchViewModel {
    var isEnabled = false
    var checkInInterval: CheckInInterval = .monthly
    var lastCheckInDate: Date?
    var nextCheckInDate: Date?
    var missedCheckIns = 0
    var isOverdue = false
    var errorMessage: String?

    private let persistence = PersistenceService.shared
    private let notifications = NotificationService.shared

    var daysUntilNextCheckIn: Int {
        guard let next = nextCheckInDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0)
    }

    var checkInStatus: CheckInStatus {
        guard isEnabled else { return .disabled }
        guard let next = nextCheckInDate else { return .neverCheckedIn }
        if Date() > next { return .overdue }
        if daysUntilNextCheckIn <= 3 { return .dueSoon }
        return .onTrack
    }

    enum CheckInStatus {
        case disabled
        case neverCheckedIn
        case onTrack
        case dueSoon
        case overdue

        var displayName: String {
            switch self {
            case .disabled: return "Disabled"
            case .neverCheckedIn: return "Never Checked In"
            case .onTrack: return "On Track"
            case .dueSoon: return "Due Soon"
            case .overdue: return "Overdue"
            }
        }

        var iconSystemName: String {
            switch self {
            case .disabled: return "pause.circle"
            case .neverCheckedIn: return "questionmark.circle"
            case .onTrack: return "checkmark.circle.fill"
            case .dueSoon: return "exclamationmark.triangle"
            case .overdue: return "xmark.circle.fill"
            }
        }
    }

    func loadState() async {
        do {
            lastCheckInDate = try await persistence.loadLastCheckIn()
            let plans = try await persistence.loadPlans()
            if let activePlan = plans.first(where: { $0.status == .active }) {
                isEnabled = activePlan.triggerConditions.contains { $0.type == .deadManSwitch && $0.isEnabled }
                nextCheckInDate = activePlan.nextCheckInDate

                if let deadManTrigger = activePlan.triggerConditions.first(where: { $0.type == .deadManSwitch }) {
                    checkInInterval = deadManTrigger.checkInInterval
                }
            }
        } catch {
            errorMessage = "Failed to load check-in state"
        }
    }

    func performCheckIn() async {
        let now = Date()
        lastCheckInDate = now
        nextCheckInDate = Calendar.current.date(byAdding: .day, value: checkInInterval.days, to: now)
        missedCheckIns = 0
        isOverdue = false

        do {
            try await persistence.saveLastCheckIn(now)

            if let next = nextCheckInDate {
                await notifications.scheduleCheckInReminder(interval: checkInInterval, nextDate: next)
            }
        } catch {
            errorMessage = "Failed to save check-in"
        }
    }
}

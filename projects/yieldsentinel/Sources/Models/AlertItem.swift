import Foundation

struct AlertItem: Identifiable, Codable, Hashable {
    let id: UUID
    let productID: String
    let productName: String
    let severity: AlertSeverity
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let scoreChange: Int?
    let previousScore: Int?
    let currentScore: Int?

    init(
        productID: String,
        productName: String,
        severity: AlertSeverity,
        title: String,
        message: String,
        scoreChange: Int? = nil,
        previousScore: Int? = nil,
        currentScore: Int? = nil
    ) {
        self.id = UUID()
        self.productID = productID
        self.productName = productName
        self.severity = severity
        self.title = title
        self.message = message
        self.timestamp = Date()
        self.isRead = false
        self.scoreChange = scoreChange
        self.previousScore = previousScore
        self.currentScore = currentScore
    }
}

enum AlertSeverity: String, Codable, CaseIterable, Hashable {
    case info = "INFO"
    case moderate = "MODERATE"
    case critical = "CRITICAL"

    var systemImage: String {
        switch self {
        case .info: return "info.circle.fill"
        case .moderate: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

struct AlertConfiguration: Identifiable, Codable, Hashable {
    let id: UUID
    let productID: String
    var scoreDropThreshold: Int // Alert when score drops by this many points
    var minimumScoreThreshold: Int // Alert when score drops below this
    var isEnabled: Bool

    init(productID: String, scoreDropThreshold: Int = 15, minimumScoreThreshold: Int = 40, isEnabled: Bool = true) {
        self.id = UUID()
        self.productID = productID
        self.scoreDropThreshold = scoreDropThreshold
        self.minimumScoreThreshold = minimumScoreThreshold
        self.isEnabled = isEnabled
    }
}

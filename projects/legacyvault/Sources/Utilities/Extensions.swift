import Foundation

extension Date {
    var daysFromNow: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: self).day ?? 0
    }

    var daysSince: Int {
        Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

extension Double {
    var formattedCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }

    var formattedCompact: String {
        if self >= 1_000_000 {
            return String(format: "$%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return String(format: "$%.1fK", self / 1_000)
        }
        return formattedCurrency
    }
}

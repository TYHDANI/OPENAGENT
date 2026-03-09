import SwiftUI

extension Color {
    /// Maps habit color name strings to SwiftUI Color values.
    /// Used because `Color("blue")` requires asset catalog entries.
    static func habitColor(_ name: String) -> Color {
        switch name.lowercased() {
        case "blue":    return .blue
        case "green":   return .green
        case "orange":  return .orange
        case "purple":  return .purple
        case "pink":    return .pink
        case "red":     return .red
        case "yellow":  return .yellow
        case "cyan":    return .cyan
        case "indigo":  return .indigo
        case "mint":    return .mint
        default:        return .blue
        }
    }
}

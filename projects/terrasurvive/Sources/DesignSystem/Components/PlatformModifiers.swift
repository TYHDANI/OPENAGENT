import SwiftUI

// MARK: - Platform-Adaptive Navigation Modifiers

extension View {
    /// Applies iOS navigation bar styling (inline title, dark toolbar).
    /// No-ops on macOS where these APIs are unavailable.
    @ViewBuilder
    func tsNavigationStyle() -> some View {
        #if os(iOS)
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TSTheme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }
}

// MARK: - Platform-Adaptive Toolbar Placement

extension ToolbarItemPlacement {
    /// Leading position in the navigation bar (iOS) or automatic (macOS).
    static var tsLeading: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .automatic
        #endif
    }

    /// Trailing position in the navigation bar (iOS) or automatic (macOS).
    static var tsTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}

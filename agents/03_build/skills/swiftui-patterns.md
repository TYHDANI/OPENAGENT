# SwiftUI Patterns Skill

## Purpose

Quick-reference patterns for building premium SwiftUI views in OPENAGENT apps. The build agent loads this when implementing UI-heavy features.

## DesignSystem Integration (Mandatory)

Every view MUST use the DesignSystem. Never use raw SwiftUI values:

```swift
// WRONG
Text("Hello").font(.title).foregroundColor(.blue).padding(16)

// CORRECT
Text("Hello").font(AppTypography.heroTitle).foregroundStyle(AppColors.accent).padding(AppSpacing.md)
```

## Premium View Template

```swift
import SwiftUI

struct FeatureView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                headerSection
                contentSection
                if !storeManager.isSubscribed {
                    upsellSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Feature")
        .refreshable { await reload() }
        .task { await loadData() }
    }

    // MARK: - Sections (keep body clean)

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accent)
                .symbolEffect(.bounce, options: .nonRepeating)

            Text("Feature Title")
                .font(AppTypography.heroTitle)
        }
        .padding(.horizontal)
    }

    private var contentSection: some View { ... }
    private var upsellSection: some View { ... }
}
```

## Loading States

Always use ShimmerView, never bare ProgressView:

```swift
if isLoading {
    VStack(spacing: AppSpacing.md) {
        ShimmerView()
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        ShimmerView()
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
    .padding(.horizontal)
} else {
    // Actual content
}
```

## Empty States

Always use AppEmptyStateView with action:

```swift
if items.isEmpty {
    AppEmptyStateView(
        icon: "tray",
        title: "No Items Yet",
        message: "Tap the + button to add your first item",
        actionTitle: "Add Item",
        action: { showAddSheet = true }
    )
}
```

## Card Pattern

Use PremiumCard for all card containers:

```swift
PremiumCard {
    VStack(alignment: .leading, spacing: AppSpacing.sm) {
        SectionHeader(title: "Statistics", icon: "chart.bar")

        HStack {
            StatBadge(label: "Total", value: "\(count)")
            StatBadge(label: "Today", value: "\(todayCount)")
        }
    }
}
```

## List Row Pattern

```swift
ForEach(items) { item in
    HStack(spacing: AppSpacing.md) {
        Image(systemName: item.icon)
            .font(.title2)
            .foregroundStyle(Color.habitColor(item.color))
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(Color.habitColor(item.color).opacity(0.15))
            )

        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(item.name)
                .font(AppTypography.bodyBold)
            Text(item.subtitle)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(AppColors.textSecondary)
    }
    .padding(AppSpacing.md)
    .background(AppColors.background)
    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    .appShadow(AppShadow.sm)
}
```

## Interactive Feedback

Every interactive element needs haptics and animation:

```swift
Button {
    AppHaptics.light()
    withAnimation(AppAnimation.springBounce) {
        isCompleted.toggle()
    }
} label: {
    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
        .contentTransition(.symbolEffect(.replace))
        .font(.title2)
        .foregroundStyle(isCompleted ? AppColors.success : AppColors.textSecondary)
}
```

## Numeric Transitions

Any number that changes should animate:

```swift
Text("\(count)")
    .font(AppTypography.metricLarge)
    .contentTransition(.numericText())
    .animation(AppAnimation.springBounce, value: count)
```

## Sheet/Modal Pattern

```swift
.sheet(isPresented: $showingSheet) {
    NavigationStack {
        SheetContentView()
            .navigationTitle("Sheet Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showingSheet = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveAction()
                        showingSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
}
```

## Accessibility Checklist

Every view must include:
- `.accessibilityLabel` on all images and icons
- `.accessibilityHint` on non-obvious interactive elements
- `.accessibilityValue` on progress indicators and sliders
- `.accessibilityAddTraits(.isButton)` on tappable non-Button views
- Support for Dynamic Type (use AppTypography, never fixed sizes)
- Sufficient color contrast (4.5:1 for text, 3:1 for large text)

## Staggered List Animation

```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemRow(item: item)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(
            AppAnimation.springBounce.delay(Double(index) * 0.05),
            value: items.count
        )
}
```

## Pull-to-Refresh

Every data-driven screen must have refreshable:

```swift
.refreshable {
    await viewModel.refresh()
}
```

## Material Overlays

Use materials for floating elements:

```swift
VStack { ... }
    .padding(AppSpacing.md)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
```

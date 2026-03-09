import SwiftUI

// MARK: - Guides View

struct GuidesView: View {
    @Environment(SurvivalService.self) private var service
    @State private var selectedCategory: GuideCategory = .fire
    @State private var searchText = ""
    @State private var selectedGuide: SurvivalGuide?

    private var filteredGuides: [SurvivalGuide] {
        let categoryGuides = service.guides(for: selectedCategory)
        if searchText.isEmpty {
            return categoryGuides
        }
        return categoryGuides.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.summary.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TSTheme.Spacing.lg) {
                    TSSearchBar(text: $searchText, placeholder: "Search survival guides...")
                        .padding(.horizontal, TSTheme.Spacing.lg)

                    categoryPicker

                    TSSectionHeader(
                        icon: selectedCategory.icon,
                        title: selectedCategory.rawValue,
                        count: filteredGuides.count
                    )

                    LazyVStack(spacing: TSTheme.Spacing.md) {
                        ForEach(filteredGuides) { guide in
                            Button {
                                selectedGuide = guide
                            } label: {
                                GuideCard(guide: guide)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, TSTheme.Spacing.lg)

                    if filteredGuides.isEmpty {
                        emptyState
                    }
                }
                .padding(.vertical, TSTheme.Spacing.md)
            }
            .background(TSTheme.background)
            .navigationTitle("Survival Guides")
            .tsNavigationStyle()
            .sheet(item: $selectedGuide) { guide in
                GuideDetailView(guide: guide)
            }
        }
    }

    // MARK: - Category Picker

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TSTheme.Spacing.sm) {
                ForEach(GuideCategory.allCases) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, TSTheme.Spacing.lg)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: TSTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(TSTheme.textTertiary)
            Text("No guides found")
                .font(TSTheme.Font.subheading())
                .foregroundStyle(TSTheme.textSecondary)
            Text("Try a different search or category")
                .font(TSTheme.Font.caption())
                .foregroundStyle(TSTheme.textTertiary)
        }
        .padding(.top, TSTheme.Spacing.xxl)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: GuideCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: TSTheme.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(category.rawValue)
                    .font(TSTheme.Font.caption())
            }
            .foregroundStyle(isSelected ? .white : TSTheme.textSecondary)
            .padding(.horizontal, TSTheme.Spacing.md)
            .padding(.vertical, TSTheme.Spacing.sm)
            .background(isSelected ? category.color : TSTheme.surfaceElevated)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Guide Card

struct GuideCard: View {
    let guide: SurvivalGuide

    var body: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                    Text(guide.title)
                        .font(TSTheme.Font.subheading(16))
                        .foregroundStyle(TSTheme.textPrimary)
                        .multilineTextAlignment(.leading)

                    if !guide.estimatedTime.isEmpty {
                        HStack(spacing: TSTheme.Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(guide.estimatedTime)
                                .font(TSTheme.Font.caption(11))
                        }
                        .foregroundStyle(TSTheme.textTertiary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: TSTheme.Spacing.xs) {
                    Text(guide.difficulty.rawValue)
                        .tsDifficultyBadge(difficulty: guide.difficulty)

                    if guide.isOfflineAvailable {
                        HStack(spacing: 2) {
                            Image(systemName: "icloud.slash.fill")
                                .font(.system(size: 10))
                            Text("Offline")
                                .font(TSTheme.Font.caption(10))
                        }
                        .foregroundStyle(TSTheme.accentGreen)
                    }
                }
            }

            Text(guide.summary)
                .font(TSTheme.Font.body(14))
                .foregroundStyle(TSTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: TSTheme.Spacing.xs) {
                Text("\(guide.steps.count) steps")
                    .font(TSTheme.Font.caption(11))
                    .foregroundStyle(TSTheme.textTertiary)

                Text("\u{2022}")
                    .foregroundStyle(TSTheme.textTertiary)

                Image(systemName: guide.category.icon)
                    .font(.system(size: 11))
                    .foregroundStyle(guide.category.color)

                Text(guide.category.rawValue)
                    .font(TSTheme.Font.caption(11))
                    .foregroundStyle(guide.category.color)
            }
        }
        .tsCard()
    }
}

// MARK: - Guide Detail View

struct GuideDetailView: View {
    let guide: SurvivalGuide
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TSTheme.Spacing.lg) {
                    // Header
                    headerSection

                    // Summary
                    Text(guide.summary)
                        .font(TSTheme.Font.body())
                        .foregroundStyle(TSTheme.textSecondary)
                        .padding(.horizontal, TSTheme.Spacing.lg)

                    // Steps
                    stepsSection

                    // Tips
                    if !guide.tips.isEmpty {
                        tipsSection
                    }

                    // Applicable Biomes
                    biomesSection
                }
                .padding(.vertical, TSTheme.Spacing.lg)
            }
            .background(TSTheme.background)
            .navigationTitle(guide.title)
            .tsNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .tsTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TSTheme.accentOrange)
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            HStack(spacing: TSTheme.Spacing.sm) {
                Image(systemName: guide.category.icon)
                    .foregroundStyle(guide.category.color)
                Text(guide.category.rawValue)
                    .font(TSTheme.Font.caption())
                    .foregroundStyle(guide.category.color)
            }

            Spacer()

            Text(guide.difficulty.rawValue)
                .tsDifficultyBadge(difficulty: guide.difficulty)

            if !guide.estimatedTime.isEmpty {
                HStack(spacing: TSTheme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(guide.estimatedTime)
                        .font(TSTheme.Font.caption(12))
                }
                .foregroundStyle(TSTheme.textTertiary)
            }
        }
        .padding(.horizontal, TSTheme.Spacing.lg)
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(icon: "list.number", title: "Steps", count: guide.steps.count)

            VStack(spacing: TSTheme.Spacing.sm) {
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: TSTheme.Spacing.md) {
                        Text("\(index + 1)")
                            .font(TSTheme.Font.mono(14))
                            .foregroundStyle(TSTheme.accentOrange)
                            .frame(width: 24, alignment: .trailing)

                        Text(step)
                            .font(TSTheme.Font.body(14))
                            .foregroundStyle(TSTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, TSTheme.Spacing.xs)

                    if index < guide.steps.count - 1 {
                        Divider()
                            .background(TSTheme.surfaceHighlight)
                            .padding(.leading, 40)
                    }
                }
            }
            .padding(.horizontal, TSTheme.Spacing.lg)
            .tsCard()
            .padding(.horizontal, TSTheme.Spacing.lg)
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(icon: "lightbulb.fill", title: "Pro Tips")

            VStack(alignment: .leading, spacing: TSTheme.Spacing.sm) {
                ForEach(guide.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: TSTheme.Spacing.sm) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(TSTheme.warningYellow)
                            .padding(.top, 2)
                        Text(tip)
                            .font(TSTheme.Font.body(14))
                            .foregroundStyle(TSTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(TSTheme.Spacing.lg)
            .background(TSTheme.warningYellow.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.md))
            .padding(.horizontal, TSTheme.Spacing.lg)
        }
    }

    private var biomesSection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(icon: "globe.americas.fill", title: "Applicable Biomes")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TSTheme.Spacing.sm) {
                    ForEach(guide.applicableBiomes) { biome in
                        HStack(spacing: TSTheme.Spacing.xs) {
                            Image(systemName: biome.icon)
                                .font(.system(size: 12))
                            Text(biome.rawValue)
                                .font(TSTheme.Font.caption(12))
                        }
                        .foregroundStyle(biome.color)
                        .padding(.horizontal, TSTheme.Spacing.md)
                        .padding(.vertical, TSTheme.Spacing.sm)
                        .background(biome.color.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, TSTheme.Spacing.lg)
            }
        }
    }
}

import SwiftUI

// MARK: - Species View

struct SpeciesView: View {
    @Environment(SurvivalService.self) private var service
    @State private var searchText = ""
    @State private var selectedRegion: String? = nil
    @State private var selectedSpecies: Species?
    @State private var showDangerousFirst = true

    private var filteredSpecies: [Species] {
        var result = service.species

        // Region filter
        if let region = selectedRegion {
            result = result.filter { $0.regions.contains(region) }
        }

        // Search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.commonName.localizedCaseInsensitiveContains(searchText) ||
                $0.scientificName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    private var dangerousFiltered: [Species] {
        filteredSpecies.filter { $0.dangerLevel == .deadly || $0.dangerLevel == .caution }
    }

    private var edibleFiltered: [Species] {
        filteredSpecies.filter { $0.isEdible }
    }

    private var safeFiltered: [Species] {
        filteredSpecies.filter { $0.dangerLevel == .safe && !$0.isEdible }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TSTheme.Spacing.lg) {
                    TSSearchBar(text: $searchText, placeholder: "Search species...")
                        .padding(.horizontal, TSTheme.Spacing.lg)

                    regionFilter

                    // Dangerous section
                    if !dangerousFiltered.isEmpty {
                        speciesSection(
                            title: "Dangerous",
                            icon: "exclamationmark.triangle.fill",
                            species: dangerousFiltered,
                            accentColor: TSTheme.danger
                        )
                    }

                    // Edible section
                    if !edibleFiltered.isEmpty {
                        speciesSection(
                            title: "Edible",
                            icon: "fork.knife",
                            species: edibleFiltered,
                            accentColor: TSTheme.safe
                        )
                    }

                    // Other safe species
                    if !safeFiltered.isEmpty {
                        speciesSection(
                            title: "Other Safe Species",
                            icon: "checkmark.shield.fill",
                            species: safeFiltered,
                            accentColor: TSTheme.textSecondary
                        )
                    }

                    if filteredSpecies.isEmpty {
                        emptyState
                    }
                }
                .padding(.vertical, TSTheme.Spacing.md)
            }
            .background(TSTheme.background)
            .navigationTitle("Species Database")
            .tsNavigationStyle()
            .sheet(item: $selectedSpecies) { species in
                SpeciesDetailView(species: species)
            }
        }
    }

    // MARK: - Region Filter

    private var regionFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TSTheme.Spacing.sm) {
                regionChip(name: "All Regions", isSelected: selectedRegion == nil) {
                    selectedRegion = nil
                }

                ForEach(service.allRegionNames, id: \.self) { region in
                    regionChip(name: region, isSelected: selectedRegion == region) {
                        selectedRegion = region
                    }
                }
            }
            .padding(.horizontal, TSTheme.Spacing.lg)
        }
    }

    private func regionChip(name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name)
                .font(TSTheme.Font.caption())
                .foregroundStyle(isSelected ? .white : TSTheme.textSecondary)
                .padding(.horizontal, TSTheme.Spacing.md)
                .padding(.vertical, TSTheme.Spacing.sm)
                .background(isSelected ? TSTheme.accentOrange : TSTheme.surfaceElevated)
                .clipShape(Capsule())
        }
    }

    // MARK: - Species Section

    private func speciesSection(
        title: String,
        icon: String,
        species: [Species],
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.sm) {
            HStack(spacing: TSTheme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(TSTheme.Font.subheading())
                    .foregroundStyle(TSTheme.textPrimary)
                Text("(\(species.count))")
                    .font(TSTheme.Font.caption())
                    .foregroundStyle(TSTheme.textTertiary)
                Spacer()
            }
            .padding(.horizontal, TSTheme.Spacing.lg)

            LazyVStack(spacing: TSTheme.Spacing.sm) {
                ForEach(species) { item in
                    Button {
                        selectedSpecies = item
                    } label: {
                        SpeciesCard(species: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, TSTheme.Spacing.lg)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: TSTheme.Spacing.md) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundStyle(TSTheme.textTertiary)
            Text("No species found")
                .font(TSTheme.Font.subheading())
                .foregroundStyle(TSTheme.textSecondary)
            Text("Try a different region or search term")
                .font(TSTheme.Font.caption())
                .foregroundStyle(TSTheme.textTertiary)
        }
        .padding(.top, TSTheme.Spacing.xxl)
    }
}

// MARK: - Species Card

struct SpeciesCard: View {
    let species: Species

    var body: some View {
        HStack(spacing: TSTheme.Spacing.md) {
            // Icon
            Image(systemName: species.kind.icon)
                .font(.system(size: 20))
                .foregroundStyle(species.dangerLevel.color)
                .frame(width: 44, height: 44)
                .background(species.dangerLevel.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.sm))

            // Info
            VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                Text(species.commonName)
                    .font(TSTheme.Font.subheading(15))
                    .foregroundStyle(TSTheme.textPrimary)
                Text(species.scientificName)
                    .font(TSTheme.Font.caption(12))
                    .foregroundStyle(TSTheme.textTertiary)
                    .italic()
                HStack(spacing: TSTheme.Spacing.xs) {
                    ForEach(species.regions.prefix(2), id: \.self) { region in
                        Text(region)
                            .font(TSTheme.Font.caption(10))
                            .foregroundStyle(TSTheme.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(TSTheme.surfaceHighlight)
                            .clipShape(Capsule())
                    }
                    if species.regions.count > 2 {
                        Text("+\(species.regions.count - 2)")
                            .font(TSTheme.Font.caption(10))
                            .foregroundStyle(TSTheme.textTertiary)
                    }
                }
            }

            Spacer()

            // Badges
            VStack(alignment: .trailing, spacing: TSTheme.Spacing.xs) {
                Text(species.dangerLevel.rawValue)
                    .tsDangerBadge(level: species.dangerLevel)

                if species.isEdible {
                    HStack(spacing: 2) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 9))
                        Text("Edible")
                            .font(TSTheme.Font.caption(10))
                    }
                    .foregroundStyle(TSTheme.accentGreen)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(TSTheme.textTertiary)
        }
        .tsCard(padding: TSTheme.Spacing.md)
    }
}

// MARK: - Species Detail View

struct SpeciesDetailView: View {
    let species: Species
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TSTheme.Spacing.lg) {
                    // Header
                    headerSection

                    // Description
                    Text(species.description)
                        .font(TSTheme.Font.body(15))
                        .foregroundStyle(TSTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, TSTheme.Spacing.lg)

                    // Danger Warning
                    if species.dangerLevel != .safe {
                        dangerWarning
                    }

                    // Identification Tips
                    identificationSection

                    // Details
                    detailsSection

                    // Regions
                    regionsSection
                }
                .padding(.vertical, TSTheme.Spacing.lg)
            }
            .background(TSTheme.background)
            .navigationTitle(species.commonName)
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
        VStack(spacing: TSTheme.Spacing.md) {
            Image(systemName: species.kind.icon)
                .font(.system(size: 48))
                .foregroundStyle(species.dangerLevel.color)
                .frame(width: 80, height: 80)
                .background(species.dangerLevel.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.lg))

            Text(species.scientificName)
                .font(TSTheme.Font.caption())
                .foregroundStyle(TSTheme.textTertiary)
                .italic()

            HStack(spacing: TSTheme.Spacing.md) {
                Text(species.dangerLevel.rawValue)
                    .tsDangerBadge(level: species.dangerLevel)

                Text(species.kind.rawValue)
                    .font(TSTheme.Font.caption(11))
                    .foregroundStyle(TSTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(TSTheme.surfaceElevated)
                    .clipShape(Capsule())

                if species.isEdible {
                    HStack(spacing: 3) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 10))
                        Text("Edible")
                    }
                    .font(TSTheme.Font.caption(11))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(TSTheme.accentGreen)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, TSTheme.Spacing.lg)
    }

    private var dangerWarning: some View {
        HStack(spacing: TSTheme.Spacing.md) {
            Image(systemName: species.dangerLevel.icon)
                .font(.system(size: 24))
                .foregroundStyle(species.dangerLevel.color)

            VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                Text(species.dangerLevel == .deadly ? "DEADLY — DO NOT TOUCH" : "EXERCISE CAUTION")
                    .font(TSTheme.Font.subheading(14))
                    .foregroundStyle(species.dangerLevel.color)
                Text(species.dangerLevel == .deadly
                    ? "This species can cause death. Avoid all contact."
                    : "This species can cause injury. Maintain safe distance."
                )
                    .font(TSTheme.Font.caption(12))
                    .foregroundStyle(TSTheme.textSecondary)
            }

            Spacer()
        }
        .padding(TSTheme.Spacing.md)
        .background(species.dangerLevel.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: TSTheme.Radius.md)
                .strokeBorder(species.dangerLevel.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, TSTheme.Spacing.lg)
    }

    private var identificationSection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(icon: "eye.fill", title: "Identification Tips")

            VStack(alignment: .leading, spacing: TSTheme.Spacing.sm) {
                ForEach(species.identificationTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: TSTheme.Spacing.sm) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(TSTheme.accentOrange)
                            .padding(.top, 6)
                        Text(tip)
                            .font(TSTheme.Font.body(14))
                            .foregroundStyle(TSTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .tsCard()
            .padding(.horizontal, TSTheme.Spacing.lg)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(icon: "info.circle.fill", title: "Details")

            VStack(spacing: TSTheme.Spacing.sm) {
                detailRow(label: "Type", value: species.kind.rawValue)
                if !species.habitat.isEmpty {
                    detailRow(label: "Habitat", value: species.habitat)
                }
                detailRow(label: "Seasonality", value: species.seasonality)
            }
            .tsCard()
            .padding(.horizontal, TSTheme.Spacing.lg)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(TSTheme.Font.caption())
                .foregroundStyle(TSTheme.textTertiary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(TSTheme.Font.body(14))
                .foregroundStyle(TSTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private var regionsSection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(icon: "globe.americas.fill", title: "Found In")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: TSTheme.Spacing.sm) {
                    ForEach(species.regions, id: \.self) { region in
                        Text(region)
                            .font(TSTheme.Font.caption(12))
                            .foregroundStyle(TSTheme.textPrimary)
                            .padding(.horizontal, TSTheme.Spacing.md)
                            .padding(.vertical, TSTheme.Spacing.sm)
                            .background(TSTheme.surfaceElevated)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, TSTheme.Spacing.lg)
            }
        }
    }
}

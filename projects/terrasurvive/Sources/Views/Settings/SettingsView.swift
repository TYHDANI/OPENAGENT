import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @Environment(SurvivalService.self) private var service
    @Environment(StoreManager.self) private var storeManager

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                // Subscription Section
                subscriptionSection

                // Offline Data Section
                offlineDataSection

                // Preferences Section
                preferencesSection

                // About Section
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(TSTheme.background)
            .navigationTitle("Settings")
            .tsNavigationStyle()
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: TSTheme.Spacing.md) {
                    Image(systemName: tierIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(tierColor)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                        Text("Current Plan")
                            .font(TSTheme.Font.caption(12))
                            .foregroundStyle(TSTheme.textTertiary)
                        Text(storeManager.currentTier.rawValue)
                            .font(TSTheme.Font.subheading())
                            .foregroundStyle(TSTheme.textPrimary)
                    }

                    Spacer()

                    if !storeManager.isPro {
                        Text("Upgrade")
                            .font(TSTheme.Font.caption())
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, TSTheme.Spacing.md)
                            .padding(.vertical, TSTheme.Spacing.sm)
                            .background(TSTheme.accentOrange)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, TSTheme.Spacing.xs)
            }

            Button {
                Task { await storeManager.restorePurchases() }
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(TSTheme.textSecondary)
                        .frame(width: 40)
                    Text("Restore Purchases")
                        .font(TSTheme.Font.body(15))
                        .foregroundStyle(TSTheme.textPrimary)
                }
            }
        } header: {
            Text("Subscription")
                .font(TSTheme.Font.caption(12))
                .foregroundStyle(TSTheme.accentOrange)
        }
        .listRowBackground(TSTheme.surface)
    }

    // MARK: - Offline Data Section

    private var offlineDataSection: some View {
        Section {
            ForEach(service.regions) { region in
                @Bindable var svc = service
                HStack(spacing: TSTheme.Spacing.md) {
                    Image(systemName: region.biome.icon)
                        .foregroundStyle(region.biome.color)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                        Text(region.name)
                            .font(TSTheme.Font.body(15))
                            .foregroundStyle(TSTheme.textPrimary)
                        Text("\(region.downloadSizeMB) MB \u{2022} \(region.biome.rawValue)")
                            .font(TSTheme.Font.caption(11))
                            .foregroundStyle(TSTheme.textTertiary)
                    }

                    Spacer()

                    Button {
                        service.toggleRegionDownload(region)
                    } label: {
                        Image(systemName: region.isDownloaded ? "checkmark.icloud.fill" : "icloud.and.arrow.down")
                            .font(.system(size: 18))
                            .foregroundStyle(region.isDownloaded ? TSTheme.accentGreen : TSTheme.waterBlue)
                    }
                }
                .padding(.vertical, TSTheme.Spacing.xs)
            }

            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundStyle(TSTheme.textTertiary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                    Text("Total Downloaded")
                        .font(TSTheme.Font.body(15))
                        .foregroundStyle(TSTheme.textPrimary)
                    let totalMB = service.regions.filter(\.isDownloaded).reduce(0) { $0 + $1.downloadSizeMB }
                    Text("\(totalMB) MB used")
                        .font(TSTheme.Font.caption(11))
                        .foregroundStyle(TSTheme.textTertiary)
                }

                Spacer()
            }
        } header: {
            Text("Offline Data")
                .font(TSTheme.Font.caption(12))
                .foregroundStyle(TSTheme.accentOrange)
        }
        .listRowBackground(TSTheme.surface)
    }

    // MARK: - Preferences Section

    private var preferencesSection: some View {
        Section {
            @Bindable var svc = service
            HStack {
                Image(systemName: "ruler")
                    .foregroundStyle(TSTheme.textSecondary)
                    .frame(width: 28)
                Picker("Units", selection: Bindable(service).unitsPreference) {
                    ForEach(UnitsPreference.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .tint(TSTheme.accentOrange)
            }
        } header: {
            Text("Preferences")
                .font(TSTheme.Font.caption(12))
                .foregroundStyle(TSTheme.accentOrange)
        }
        .listRowBackground(TSTheme.surface)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(TSTheme.textSecondary)
                    .frame(width: 28)
                Text("Version")
                    .font(TSTheme.Font.body(15))
                    .foregroundStyle(TSTheme.textPrimary)
                Spacer()
                Text("1.0.0")
                    .font(TSTheme.Font.caption())
                    .foregroundStyle(TSTheme.textTertiary)
            }

            HStack {
                Image(systemName: "book.closed")
                    .foregroundStyle(TSTheme.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                    Text("Guides")
                        .font(TSTheme.Font.body(15))
                        .foregroundStyle(TSTheme.textPrimary)
                    Text("Based on U.S. Army FM 21-76")
                        .font(TSTheme.Font.caption(11))
                        .foregroundStyle(TSTheme.textTertiary)
                }
                Spacer()
            }

            HStack {
                Image(systemName: "leaf")
                    .foregroundStyle(TSTheme.textSecondary)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                    Text("Species Data")
                        .font(TSTheme.Font.body(15))
                        .foregroundStyle(TSTheme.textPrimary)
                    Text("Sources: GBIF, iNaturalist, USDA PLANTS")
                        .font(TSTheme.Font.caption(11))
                        .foregroundStyle(TSTheme.textTertiary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: TSTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(TSTheme.warningYellow)
                        .frame(width: 28)
                    Text("Disclaimer")
                        .font(TSTheme.Font.body(15))
                        .foregroundStyle(TSTheme.textPrimary)
                }

                Text("TerraSurvive is for educational and preparedness purposes only. Species identification should always be verified by an expert before consumption. In a real emergency, call your local emergency number.")
                    .font(TSTheme.Font.caption(11))
                    .foregroundStyle(TSTheme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } header: {
            Text("About")
                .font(TSTheme.Font.caption(12))
                .foregroundStyle(TSTheme.accentOrange)
        }
        .listRowBackground(TSTheme.surface)
    }

    // MARK: - Helpers

    private var tierIcon: String {
        switch storeManager.currentTier {
        case .free: return "person.crop.circle"
        case .pro: return "crown.fill"
        case .lifetime: return "mountain.2.fill"
        }
    }

    private var tierColor: Color {
        switch storeManager.currentTier {
        case .free: return TSTheme.textSecondary
        case .pro: return TSTheme.accentOrange
        case .lifetime: return TSTheme.warningYellow
        }
    }
}

// MARK: - Paywall View

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TSTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: TSTheme.Spacing.md) {
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(TSTheme.accentOrange)

                        Text("Upgrade to Pro")
                            .font(TSTheme.Font.heading(28))
                            .foregroundStyle(TSTheme.textPrimary)

                        Text("Unlock the full survival toolkit")
                            .font(TSTheme.Font.body())
                            .foregroundStyle(TSTheme.textSecondary)
                    }
                    .padding(.top, TSTheme.Spacing.xl)

                    // Features
                    VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
                        featureRow(icon: "map.fill", text: "Unlimited offline region downloads")
                        featureRow(icon: "book.fill", text: "Full survival guide library (30+ techniques)")
                        featureRow(icon: "leaf.fill", text: "Complete species database (200+ species)")
                        featureRow(icon: "antenna.radiowaves.left.and.right", text: "Advanced SOS beacon with satellite relay")
                        featureRow(icon: "globe.americas.fill", text: "Emergency contacts for 190+ countries")
                    }
                    .tsCard()
                    .padding(.horizontal, TSTheme.Spacing.lg)

                    // Pricing
                    VStack(spacing: TSTheme.Spacing.md) {
                        // Yearly
                        pricingCard(
                            title: "Pro Yearly",
                            price: "$49.99/year",
                            subtitle: "7-day free trial",
                            isRecommended: true
                        ) {
                            if let product = storeManager.proYearlyProduct {
                                Task { _ = await storeManager.purchase(product) }
                            }
                        }

                        // Lifetime
                        pricingCard(
                            title: "Expedition Lifetime",
                            price: "$99.99",
                            subtitle: "One-time purchase, forever",
                            isRecommended: false
                        ) {
                            if let product = storeManager.lifetimeProduct {
                                Task { _ = await storeManager.purchase(product) }
                            }
                        }
                    }
                    .padding(.horizontal, TSTheme.Spacing.lg)

                    if let error = storeManager.errorMessage {
                        Text(error)
                            .font(TSTheme.Font.caption(12))
                            .foregroundStyle(TSTheme.danger)
                            .padding(.horizontal, TSTheme.Spacing.lg)
                    }

                    // Legal
                    Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                        .font(TSTheme.Font.caption(10))
                        .foregroundStyle(TSTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, TSTheme.Spacing.xl)
                }
                .padding(.bottom, TSTheme.Spacing.xxl)
            }
            .background(TSTheme.background)
            .toolbar {
                ToolbarItem(placement: .tsTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(TSTheme.textSecondary)
                }
            }
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: TSTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(TSTheme.accentOrange)
                .frame(width: 24)
            Text(text)
                .font(TSTheme.Font.body(14))
                .foregroundStyle(TSTheme.textPrimary)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(TSTheme.accentGreen)
                .font(.system(size: 14))
        }
    }

    private func pricingCard(
        title: String,
        price: String,
        subtitle: String,
        isRecommended: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: TSTheme.Spacing.sm) {
                if isRecommended {
                    Text("RECOMMENDED")
                        .font(TSTheme.Font.caption(10))
                        .fontWeight(.bold)
                        .foregroundStyle(TSTheme.accentOrange)
                }

                Text(title)
                    .font(TSTheme.Font.subheading())
                    .foregroundStyle(TSTheme.textPrimary)

                Text(price)
                    .font(TSTheme.Font.heading(28))
                    .foregroundStyle(isRecommended ? TSTheme.accentOrange : TSTheme.textPrimary)

                Text(subtitle)
                    .font(TSTheme.Font.caption(12))
                    .foregroundStyle(TSTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TSTheme.Spacing.lg)
            .background(isRecommended ? TSTheme.accentOrange.opacity(0.1) : TSTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: TSTheme.Radius.md)
                    .strokeBorder(
                        isRecommended ? TSTheme.accentOrange : TSTheme.surfaceHighlight,
                        lineWidth: isRecommended ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

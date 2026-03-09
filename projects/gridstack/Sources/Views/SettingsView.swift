import SwiftUI

struct SettingsView: View {
    @Environment(EnergyService.self) private var service
    @Environment(StoreManager.self) private var storeManager
    @State private var showingPaywall = false
    @State private var showingRestore = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    subscriptionCard
                    dataControlsCard
                    aboutCard
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .darkNavigationBar()
            .sheet(isPresented: $showingPaywall) {
                paywallSheet
            }
        }
    }

    // MARK: - Subscription Card

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Label("Subscription", systemImage: "crown.fill")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text(storeManager.isPro ? "PRO" : "FREE")
                    .font(AppTypography.badge)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(storeManager.isPro ? AppColors.accent : AppColors.textTertiary)
                    .clipShape(Capsule())
            }

            if storeManager.isPro {
                proStatusView
            } else {
                freeStatusView
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .strokeBorder(storeManager.isPro ? AppColors.accent.opacity(0.3) : AppColors.divider, lineWidth: 1)
        )
    }

    private var proStatusView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(AppColors.accent)
                Text("GridStack Pro Active")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.accent)
            }

            Text("You have access to all features including multi-program earnings aggregation, heat reclamation analytics, and tax export.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var freeStatusView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Upgrade to GridStack Pro for full access:")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                featureRow("Multi-program earnings aggregation")
                featureRow("Heat reclamation ROI analytics")
                featureRow("Advanced energy charts")
                featureRow("Tax export for energy income")
                featureRow("Priority support")
            }

            Button {
                showingPaywall = true
                AppHaptics.impact()
            } label: {
                Text("View Plans")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppGradient.accent())
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            }

            Button {
                Task {
                    await storeManager.restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColors.accent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundStyle(AppColors.success)
            Text(text)
                .font(AppTypography.callout)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    // MARK: - Data Controls

    private var dataControlsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("Data & Privacy", systemImage: "lock.shield.fill")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            settingsRow(icon: "arrow.down.doc", label: "Export Earnings Data", detail: "CSV") {
                AppHaptics.success()
            }
            Divider().overlay(AppColors.divider)
            settingsRow(icon: "arrow.clockwise", label: "Refresh Energy Data", detail: nil) {
                AppHaptics.impact()
            }
            Divider().overlay(AppColors.divider)
            settingsRow(icon: "bell.badge", label: "DR Event Notifications", detail: "On") {
                AppHaptics.selection()
            }
            Divider().overlay(AppColors.divider)
            settingsRow(icon: "thermometer", label: "Thermostat Connection", detail: service.prosumerProfile.smartThermostat?.rawValue ?? "None") {
                AppHaptics.selection()
            }
            Divider().overlay(AppColors.divider)
            settingsRow(icon: "building.columns", label: "Utility Provider", detail: service.prosumerProfile.utilityProvider) {
                AppHaptics.selection()
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    private func settingsRow(icon: String, label: String, detail: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppColors.accent)
                    .frame(width: 28)
                Text(label)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if let detail {
                    Text(detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.vertical, AppSpacing.xxs)
        }
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Label("About", systemImage: "info.circle")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack {
                Text("Version")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("1.0.0")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Divider().overlay(AppColors.divider)
            HStack {
                Text("Bundle ID")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("com.openagent.gridstack")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            Divider().overlay(AppColors.divider)

            Button {
                // Privacy policy link
            } label: {
                HStack {
                    Text("Privacy Policy")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            Divider().overlay(AppColors.divider)

            Button {
                // Terms of service link
            } label: {
                HStack {
                    Text("Terms of Service")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }

    // MARK: - Paywall Sheet

    private var paywallSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Hero
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(AppColors.accent)

                        Text("GridStack Pro")
                            .font(AppTypography.heroTitle)
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Unlock the full power of your energy earnings")
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.lg)

                    // Features
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        proFeature(icon: "chart.bar.doc.horizontal.fill", title: "Multi-Program Aggregation", desc: "Track earnings across all your DR programs in one view")
                        proFeature(icon: "flame.fill", title: "Heat Reclamation Analytics", desc: "Detailed ROI tracking for compute heat reclamation")
                        proFeature(icon: "chart.xyaxis.line", title: "Advanced Charts", desc: "Historical trends, projections, and cost analysis")
                        proFeature(icon: "doc.text.fill", title: "Tax Export", desc: "Export energy income data for tax reporting")
                        proFeature(icon: "person.fill.questionmark", title: "Priority Support", desc: "Direct access to the GridStack team")
                    }
                    .padding(.horizontal, AppSpacing.md)

                    // Pricing
                    VStack(spacing: AppSpacing.sm) {
                        pricingOption(
                            title: "Monthly",
                            price: "$4.99/mo",
                            subtitle: nil,
                            productID: StoreManager.monthlyProductID
                        )
                        pricingOption(
                            title: "Yearly",
                            price: "$39.99/yr",
                            subtitle: "Save 33%",
                            productID: StoreManager.yearlyProductID
                        )
                    }
                    .padding(.horizontal, AppSpacing.md)

                    Text("Cancel anytime. Payment charged to Apple ID.")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, AppSpacing.xxl)
            }
            .background(AppColors.background.ignoresSafeArea())
            .inlineTitleDisplayMode()
            .darkNavigationBar()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        showingPaywall = false
                    }
                    .foregroundStyle(AppColors.accent)
                }
            }
        }
    }

    private func proFeature(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppColors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(desc)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func pricingOption(title: String, price: String, subtitle: String?, productID: String) -> some View {
        Button {
            Task {
                if let product = storeManager.products.first(where: { $0.id == productID }) {
                    try? await storeManager.purchase(product)
                    if storeManager.isPro {
                        showingPaywall = false
                    }
                }
            }
            AppHaptics.impact()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.success)
                    }
                }
                Spacer()
                Text(price)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.accent)
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(AppColors.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    SettingsView()
        .environment(EnergyService())
        .environment(StoreManager())
        .preferredColorScheme(.dark)
}

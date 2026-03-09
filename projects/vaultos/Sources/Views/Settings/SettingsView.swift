import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(PersistenceService.self) private var persistence
    @State private var showManageSubscription = false

    var body: some View {
        NavigationStack {
            List {
                // Subscription
                Section("Subscription") {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(AppColors.accent)
                        VStack(alignment: .leading) {
                            Text(store.currentTier.label).font(.headline)
                            Text(store.currentTier.monthlyPrice + "/mo").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.currentTier == .free {
                            Button("Upgrade") { showManageSubscription = true }
                                .buttonStyle(.borderedProminent)
                                .tint(AppColors.accent)
                        }
                    }

                    if store.currentTier != .free {
                        LabeledContent("Max Entities", value: "\(store.currentTier.maxEntities)")
                        LabeledContent("Max Beneficiaries", value: "\(store.currentTier.maxBeneficiaries)")
                        LabeledContent("Wash Sale Detection", value: store.currentTier.hasWashSaleDetection ? "Yes" : "No")
                        LabeledContent("Form 8949 Export", value: store.currentTier.hasForm8949Export ? "Yes" : "No")
                        LabeledContent("Succession Planning", value: store.currentTier.hasSuccessionPlanning ? "Yes" : "No")
                    }
                }

                // Entities
                Section("Legal Entities") {
                    ForEach(persistence.entities) { entity in
                        HStack {
                            Image(systemName: entity.entityType.icon)
                                .foregroundStyle(AppColors.accent)
                            VStack(alignment: .leading) {
                                Text(entity.name).font(.subheadline.bold())
                                Text(entity.entityType.rawValue).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Data
                Section("Data") {
                    Button {
                        persistence.save()
                    } label: {
                        Label("Save Data", systemImage: "arrow.down.doc")
                    }

                    Button {
                        persistence.load()
                    } label: {
                        Label("Reload Data", systemImage: "arrow.clockwise")
                    }

                    Button(role: .destructive) {
                        // Reset to sample data
                        persistence.entities = SampleData.entities
                        persistence.accounts = SampleData.accounts
                        persistence.products = SampleData.products
                        persistence.transactions = []
                        persistence.taxLots = []
                        persistence.alerts = []
                        persistence.beneficiaries = []
                        persistence.plans = []
                        persistence.save()
                    } label: {
                        Label("Reset to Sample Data", systemImage: "trash")
                    }
                }

                // About
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("App", value: "VaultOS")
                }

                Section {
                    Button("Restore Purchases") {
                        Task { await store.restore() }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showManageSubscription) {
                SubscriptionView()
            }
        }
    }
}

struct SubscriptionView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.accent)

                Text("Upgrade to Pro")
                    .font(.title.bold())

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "shield.checkered", text: "Unlimited risk scans")
                    FeatureRow(icon: "doc.text", text: "Form 8949 export")
                    FeatureRow(icon: "exclamationmark.triangle", text: "Cross-entity wash sale detection")
                    FeatureRow(icon: "person.2", text: "Succession planning")
                    FeatureRow(icon: "building.columns", text: "Up to 5 legal entities")
                }
                .padding()

                ForEach(store.availableProducts, id: \.id) { product in
                    Button {
                        Task { try? await store.purchase(product) }
                    } label: {
                        Text("\(product.displayName) — \(product.displayPrice)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.accent)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()
            }
            .padding()
            .background(AppColors.background)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppColors.accent)
                .frame(width: 24)
            Text(text)
        }
    }
}

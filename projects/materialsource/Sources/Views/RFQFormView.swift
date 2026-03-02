import SwiftUI
import SwiftData

struct RFQFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel: RFQViewModel?

    let material: Material
    let supplier: Supplier

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    formContent(viewModel)
                } else {
                    ProgressView()
                        .onAppear {
                            setupViewModel()
                        }
                }
            }
            .navigationTitle("Request Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        Task {
                            await submitRFQ()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel?.quantity.isEmpty ?? true || viewModel?.isSubmitting ?? false)
                }
            }
        }
    }

    @ViewBuilder
    private func formContent(_ viewModel: RFQViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Material & Supplier Info
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Material")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "cube.fill")
                                .foregroundStyle(.accentColor)
                            VStack(alignment: .leading) {
                                Text(material.name)
                                    .font(.headline)
                                if let spec = material.specifications.first {
                                    Text(spec.fullSpec)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Supplier")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.accentColor)
                            VStack(alignment: .leading) {
                                Text(supplier.name)
                                    .font(.headline)
                                HStack(spacing: 12) {
                                    Label(supplier.location, systemImage: "location")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Label(supplier.leadTimeRange, systemImage: "clock")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Quantity Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Quantity Required", systemImage: "number")
                        .font(.headline)

                    HStack(spacing: 12) {
                        TextField("Amount", text: $viewModel.quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                        Picker("Unit", selection: $viewModel.unit) {
                            ForEach(viewModel.units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    if let minOrder = supplier.minimumOrderQuantity {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("Minimum order: \(minOrder)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Specifications Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Additional Specifications", systemImage: "doc.text")
                        .font(.headline)

                    TextEditor(text: $viewModel.specifications)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Target Date Section
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $viewModel.includeTargetDate) {
                        Label("Add Target Delivery Date", systemImage: "calendar")
                            .font(.headline)
                    }

                    if viewModel.includeTargetDate {
                        DatePicker(
                            "Target Date",
                            selection: Binding(
                                get: { viewModel.targetDate ?? Date() },
                                set: { viewModel.targetDate = $0 }
                            ),
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Pro Upsell for free users
                if !viewModel.isProUser {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.orange)

                        Text("Free Account Limit")
                            .font(.headline)

                        Text("You can submit 1 RFQ per month on the free plan. Upgrade to Pro for unlimited RFQs.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        NavigationLink(destination: PaywallView()) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                                Text("Upgrade to Pro")
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func setupViewModel() {
        let rfqService = RFQService(modelContext: modelContext)
        viewModel = RFQViewModel(rfqService: rfqService, storeManager: storeManager)
    }

    private func submitRFQ() async {
        guard let viewModel = viewModel else { return }

        let success = await viewModel.createRFQ(
            material: material,
            supplier: supplier
        )

        if success {
            dismiss()
        }
    }
}

#Preview {
    RFQFormView(
        material: Material(
            name: "Ti-6Al-4V",
            category: "Titanium Alloys",
            descriptionText: "Premium titanium alloy"
        ),
        supplier: Supplier(
            name: "Test Supplier",
            location: "USA",
            leadTimeRange: "2-4 weeks",
            minimumOrderQuantity: "10 lbs"
        )
    )
    .environment(StoreManager())
    .modelContainer(for: [Material.self, Supplier.self, RFQ.self])
}
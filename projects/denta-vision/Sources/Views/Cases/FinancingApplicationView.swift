import SwiftUI

struct FinancingApplicationView: View {
    @Environment(\.dismiss) private var dismiss

    let patient: Patient
    let option: FinancingOption
    let amount: Decimal

    @State private var financingService = FinancingService()
    @State private var application: FinancingApplication? = nil
    @State private var isSubmitting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Application Details
                detailsSection

                // Patient Info
                patientSection

                // Action
                actionSection
            }
            .padding()
        }
        .navigationTitle("Financing Application")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue.gradient)

            Text(option.provider.rawValue)
                .font(.title2)
                .fontWeight(.bold)

            if option.isPromotional, let promo = option.promoDetails {
                Text(promo)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
            }
        }
    }

    private var detailsSection: some View {
        GroupBox("Financing Details") {
            VStack(spacing: 12) {
                DetailRow(label: "Amount", value: amount.formatted(.currency(code: "USD")))
                DetailRow(label: "Term", value: "\(option.termMonths) months")
                DetailRow(label: "Monthly Payment", value: option.monthlyPayment.formatted(.currency(code: "USD")))
                DetailRow(label: "APR", value: option.interestRate > 0 ? "\(NSDecimalNumber(decimal: option.interestRate * 100).intValue)%" : "0%")

                if option.downPayment > 0 {
                    DetailRow(label: "Down Payment", value: option.downPayment.formatted(.currency(code: "USD")))
                }

                Divider()

                DetailRow(label: "Total Cost", value: option.totalCost.formatted(.currency(code: "USD")), isBold: true)
            }
        }
    }

    private var patientSection: some View {
        GroupBox("Patient Information") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Name")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(patient.fullName)
                        .fontWeight(.medium)
                }

                if let email = patient.email {
                    HStack {
                        Text("Email")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(email)
                    }
                }

                if let phone = patient.phone {
                    HStack {
                        Text("Phone")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(phone)
                    }
                }
            }
            .font(.subheadline)
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            if let application = application {
                // Application submitted
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)

                    Text("Application Submitted")
                        .font(.headline)

                    Text("Status: \(application.status.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let url = application.applicationURL {
                        Link("Complete Application Online", destination: url)
                            .font(.subheadline)
                            .padding(.top, 8)
                    }
                }
                .padding()
            } else {
                // Submit button
                Button {
                    submitApplication()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Start \(option.provider.rawValue) Application")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isSubmitting)

                Text("You will be redirected to complete the application with \(option.provider.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Actions

    private func submitApplication() {
        isSubmitting = true
        Task {
            let result = await financingService.startApplication(
                patient: patient,
                option: option,
                amount: amount
            )
            await MainActor.run {
                application = result
                isSubmitting = false
            }
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(isBold ? .bold : .medium)
        }
        .font(.subheadline)
    }
}

#Preview {
    NavigationStack {
        FinancingApplicationView(
            patient: Patient(
                firstName: "John",
                lastName: "Doe",
                dateOfBirth: Date(),
                email: "john@example.com",
                phone: "(555) 123-4567"
            ),
            option: FinancingOption(
                provider: .careCredit,
                termMonths: 12,
                monthlyPayment: 291.67,
                interestRate: 0,
                totalCost: 3500,
                isPromotional: true,
                promoDetails: "0% APR for 12 months"
            ),
            amount: 3500
        )
    }
}

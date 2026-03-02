import SwiftUI

struct DentalChartDetailView: View {
    @Environment(DataManager.self) private var dataManager

    let chart: DentalChart

    @State private var selectedTooth: Tooth? = nil

    private var patient: Patient? {
        dataManager.patients.first { $0.id == chart.patientId }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chart Info Header
                chartInfoHeader

                // Dental Chart Visual
                dentalChartView

                // Conditions Summary
                conditionsSummary

                // Chart Notes
                if !chart.notes.isEmpty {
                    notesSection
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .navigationTitle("Dental Chart")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTooth) { tooth in
            ToothDetailView(tooth: tooth) { _ in }
                .presentationDetents([.medium])
        }
    }

    // MARK: - Sections

    private var chartInfoHeader: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Label("Patient", systemImage: "person")
                    Spacer()
                    Text(patient?.fullName ?? "Unknown")
                        .fontWeight(.medium)
                }

                HStack {
                    Label("Date", systemImage: "calendar")
                    Spacer()
                    Text(chart.recordingDate.formatted(date: .abbreviated, time: .shortened))
                        .fontWeight(.medium)
                }

                if let duration = chart.recordingDuration {
                    HStack {
                        Label("Recording Duration", systemImage: "mic")
                        Spacer()
                        Text("\(Int(duration)) seconds")
                            .fontWeight(.medium)
                    }
                }
            }
            .font(.subheadline)
        }
    }

    private var dentalChartView: some View {
        VStack(spacing: 16) {
            Text("Dental Chart Overview")
                .font(.headline)

            // Upper Teeth
            VStack(spacing: 8) {
                Text("Upper")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(1...16, id: \.self) { number in
                        ToothView(
                            tooth: tooth(number: number),
                            isSelected: false
                        ) {
                            selectedTooth = tooth(number: number)
                        }
                    }
                }
            }

            Divider()

            // Lower Teeth
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach((17...32).reversed(), id: \.self) { number in
                        ToothView(
                            tooth: tooth(number: number),
                            isSelected: false
                        ) {
                            selectedTooth = tooth(number: number)
                        }
                    }
                }

                Text("Lower")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Legend
            legendView
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Legend")
                .font(.caption)
                .fontWeight(.medium)

            HStack(spacing: 16) {
                LegendItem(color: .green, text: "Healthy")
                LegendItem(color: .red, text: "Cavity/Decay")
                LegendItem(color: .orange, text: "Filled/Crown")
                LegendItem(color: .gray, text: "Missing")
            }
            .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var conditionsSummary: some View {
        GroupBox("Conditions Summary") {
            VStack(alignment: .leading, spacing: 12) {
                let allConditions = Dictionary(grouping: chart.teeth.flatMap { tooth in
                    tooth.conditions.map { (tooth: tooth, condition: $0) }
                }, by: \.condition)

                if allConditions.isEmpty {
                    Text("No conditions recorded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(allConditions.keys), id: \.self) { condition in
                        HStack {
                            Text(condition.rawValue)
                                .font(.subheadline)

                            Spacer()

                            Text("Teeth: \(toothNumbers(for: allConditions[condition] ?? []))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var notesSection: some View {
        GroupBox("Chart Notes") {
            Text(chart.notes)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                if let patient = patient {
                    CreateCasePresentationView(
                        patient: patient,
                        fromChart: chart
                    )
                }
            } label: {
                Label("Create Treatment Plan", systemImage: "doc.text.badge.plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(patient == nil)

            NavigationLink {
                VoiceChartingView(
                    patientId: chart.patientId,
                    existingChart: chart
                )
            } label: {
                Label("Edit Chart", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
    }

    // MARK: - Helpers

    private func tooth(number: Int) -> Tooth {
        chart.teeth.first(where: { $0.number == number }) ?? Tooth(number: number)
    }

    private func toothNumbers(for items: [(tooth: Tooth, condition: ToothCondition)]) -> String {
        let numbers = items.map { $0.tooth.number }.sorted()
        return numbers.map { "#\($0)" }.joined(separator: ", ")
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DentalChartDetailView(
            chart: DentalChart(
                patientId: UUID(),
                teeth: Tooth.createFullMouth()
            )
        )
        .environment(DataManager())
    }
}
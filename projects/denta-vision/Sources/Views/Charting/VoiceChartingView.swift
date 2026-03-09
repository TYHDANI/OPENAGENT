import SwiftUI
import Speech
#if canImport(UIKit)
import UIKit
#endif

struct VoiceChartingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataManager.self) private var dataManager

    let patientId: UUID?

    @State private var voiceService = VoiceRecognitionService()
    @State private var dentalChart: DentalChart
    @State private var selectedTooth: Tooth? = nil
    @State private var showingToothDetail = false
    @State private var isAuthorized = false
    @State private var showingPermissionAlert = false
    @State private var chartNotes = ""
    @State private var recordingStartTime: Date? = nil

    init(patientId: UUID? = nil, existingChart: DentalChart? = nil) {
        self.patientId = patientId

        if let chart = existingChart {
            _dentalChart = State(initialValue: chart)
        } else if let patientId = patientId {
            _dentalChart = State(initialValue: DentalChart(patientId: patientId))
        } else {
            // Shouldn't happen, but provide a default
            _dentalChart = State(initialValue: DentalChart(patientId: UUID()))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Dental Chart Visual
            ScrollView {
                VStack(spacing: 20) {
                    dentalChartView
                    transcriptionView
                    notesView
                }
                .padding()
            }

            // Recording Controls
            recordingControls
        }
        .navigationTitle("Voice Charting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChart()
                }
                .disabled(dentalChart.recordingDate == Date())
            }
        }
        .sheet(isPresented: $showingToothDetail) {
            if let tooth = selectedTooth {
                ToothDetailView(tooth: tooth, onUpdate: updateTooth)
            }
        }
        .alert("Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                #if os(iOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to use voice charting.")
        }
        .onAppear {
            setupVoiceService()
            checkAuthorization()
        }
    }

    // MARK: - Views

    private var dentalChartView: some View {
        VStack(spacing: 16) {
            Text("Tap teeth to edit • Voice commands: \"Tooth [number] [condition]\"")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Upper Teeth
            VStack(spacing: 8) {
                Text("Upper")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    ForEach(1...16, id: \.self) { number in
                        ToothView(
                            tooth: tooth(number: number),
                            isSelected: selectedTooth?.number == number
                        ) {
                            selectTooth(number: number)
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
                            isSelected: selectedTooth?.number == number
                        ) {
                            selectTooth(number: number)
                        }
                    }
                }

                Text("Lower")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var transcriptionView: some View {
        GroupBox("Voice Transcript") {
            ScrollView {
                Text(voiceService.transcribedText.isEmpty ? "Start recording to see transcript..." : voiceService.transcribedText)
                    .font(.subheadline)
                    .foregroundStyle(voiceService.transcribedText.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(height: 100)
        }
    }

    private var notesView: some View {
        GroupBox("Chart Notes") {
            TextField("Additional notes...", text: $chartNotes, axis: .vertical)
                .lineLimit(3...5)
                .font(.subheadline)
                .textFieldStyle(.plain)
                .padding(8)
        }
    }

    private var recordingControls: some View {
        VStack(spacing: 16) {
            if voiceService.isRecording {
                // Recording indicator
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse)

                    Text("Recording...")
                        .font(.headline)

                    Spacer()

                    if let startTime = recordingStartTime {
                        Text(timeElapsed(from: startTime))
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding(.horizontal)
            }

            // Record button
            Button {
                toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(voiceService.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)

                    Image(systemName: voiceService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
            .disabled(!isAuthorized)

            Text(voiceService.isRecording ? "Tap to stop" : "Tap to start voice charting")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
    }

    // MARK: - Helpers

    private func tooth(number: Int) -> Tooth {
        dentalChart.teeth.first(where: { $0.number == number }) ?? Tooth(number: number)
    }

    private func selectTooth(number: Int) {
        selectedTooth = tooth(number: number)
        showingToothDetail = true
    }

    private func updateTooth(_ updatedTooth: Tooth) {
        if let index = dentalChart.teeth.firstIndex(where: { $0.number == updatedTooth.number }) {
            dentalChart.teeth[index] = updatedTooth
        }
    }

    private func setupVoiceService() {
        voiceService.onDentalCommand = { command in
            handleDentalCommand(command)
        }
    }

    private func checkAuthorization() {
        Task {
            isAuthorized = await voiceService.requestAuthorization()
            if !isAuthorized {
                showingPermissionAlert = true
            }
        }
    }

    private func toggleRecording() {
        if voiceService.isRecording {
            voiceService.stopRecording()
            if let startTime = recordingStartTime {
                dentalChart.recordingDuration = Date().timeIntervalSince(startTime)
            }
            recordingStartTime = nil
        } else {
            do {
                try voiceService.startRecording()
                recordingStartTime = Date()
            } catch {
                // Handle error
            }
        }
    }

    private func handleDentalCommand(_ command: DentalCommand) {
        switch command {
        case .toothCondition(let toothNumber, let condition):
            if let index = dentalChart.teeth.firstIndex(where: { $0.number == toothNumber }) {
                if !dentalChart.teeth[index].conditions.contains(condition) {
                    dentalChart.teeth[index].conditions.append(condition)
                }
            }

        case .treatment(let type, let toothNumbers):
            // Add treatment to the chart's first matching tooth
            if let firstTooth = toothNumbers.first,
               let index = dentalChart.teeth.firstIndex(where: { $0.number == firstTooth }) {
                let treatment = Treatment(
                    type: type,
                    toothNumbers: toothNumbers,
                    description: "Voice recorded: \(type.rawValue)",
                    estimatedCost: 0
                )
                dentalChart.teeth[index].treatments.append(treatment)
            }

        case .periodontalMeasurement(_, _):
            break

        case .note(let text):
            chartNotes += "\n" + text
        }
    }

    private func timeElapsed(from startTime: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func saveChart() {
        dentalChart.notes = chartNotes

        do {
            // Check if this chart already exists in the data store
            let existingCharts = dataManager.getDentalCharts(for: dentalChart.patientId)
            if existingCharts.contains(where: { $0.id == dentalChart.id }) {
                try dataManager.updateDentalChart(dentalChart)
            } else {
                try dataManager.createDentalChart(dentalChart)
            }
            dismiss()
        } catch {
            // Handle error
        }
    }
}

// MARK: - Tooth View

struct ToothView: View {
    let tooth: Tooth
    let isSelected: Bool
    let action: () -> Void

    private var backgroundColor: Color {
        if isSelected {
            return .blue
        }

        // Color based on conditions
        if tooth.conditions.contains(.missing) {
            return .gray
        } else if tooth.conditions.contains(.cavity) || tooth.conditions.contains(.decay) {
            return .red
        } else if tooth.conditions.contains(.filling) || tooth.conditions.contains(.crown) {
            return .orange
        } else if tooth.conditions.contains(.healthy) || tooth.conditions.isEmpty {
            return .green
        } else {
            return .yellow
        }
    }

    var body: some View {
        Button(action: action) {
            Text("\(tooth.number)")
                .font(.caption2)
                .fontWeight(.medium)
                .frame(width: 22, height: 22)
                .background(backgroundColor.opacity(0.8))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
    }
}

// MARK: - Tooth Detail View

struct ToothDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let tooth: Tooth
    let onUpdate: (Tooth) -> Void

    @State private var selectedConditions = Set<ToothCondition>()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Tooth Information") {
                    HStack {
                        Text("Tooth Number")
                        Spacer()
                        Text("#\(tooth.number)")
                            .fontWeight(.medium)
                    }

                    HStack {
                        Text("Name")
                        Spacer()
                        Text(tooth.name)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Quadrant")
                        Spacer()
                        Text(tooth.quadrant)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Conditions") {
                    ForEach(ToothCondition.allCases, id: \.self) { condition in
                        Toggle(condition.rawValue, isOn: binding(for: condition))
                    }
                }

                Section("Notes") {
                    TextField("Additional notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Tooth #\(tooth.number)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTooth()
                    }
                }
            }
            .onAppear {
                loadToothData()
            }
        }
    }

    private func binding(for condition: ToothCondition) -> Binding<Bool> {
        Binding(
            get: { selectedConditions.contains(condition) },
            set: { isOn in
                if isOn {
                    selectedConditions.insert(condition)
                } else {
                    selectedConditions.remove(condition)
                }
            }
        )
    }

    private func loadToothData() {
        selectedConditions = Set(tooth.conditions)
        notes = tooth.notes
    }

    private func saveTooth() {
        var updatedTooth = tooth
        updatedTooth.conditions = Array(selectedConditions)
        updatedTooth.notes = notes
        onUpdate(updatedTooth)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        VoiceChartingView(patientId: UUID())
            .environment(DataManager())
    }
}
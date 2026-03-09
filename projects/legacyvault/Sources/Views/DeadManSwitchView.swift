import SwiftUI

struct DeadManSwitchView: View {
    @State private var viewModel = DeadManSwitchViewModel()
    @State private var showingConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusCard
                checkInCard
                settingsCard
                escalationInfo
            }
            .padding()
        }
        .navigationTitle("Dead-Man Switch")
        .task {
            await viewModel.loadState()
        }
        .alert("Confirm Check-In", isPresented: $showingConfirmation) {
            Button("Confirm — I'm OK") {
                Task { await viewModel.performCheckIn() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This confirms you are active and resets the dead-man switch timer.")
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 16) {
            Image(systemName: viewModel.checkInStatus.iconSystemName)
                .font(.system(size: 48))
                .foregroundStyle(statusColor)

            Text(viewModel.checkInStatus.displayName)
                .font(.title2.bold())
                .foregroundStyle(statusColor)

            if viewModel.isEnabled {
                if viewModel.daysUntilNextCheckIn > 0 {
                    Text("\(viewModel.daysUntilNextCheckIn) days until next check-in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if viewModel.checkInStatus == .overdue {
                    Text("Check-in is overdue!")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var statusColor: Color {
        switch viewModel.checkInStatus {
        case .onTrack: return .green
        case .dueSoon: return .orange
        case .overdue: return .red
        case .disabled, .neverCheckedIn: return .gray
        }
    }

    // MARK: - Check-In Card

    private var checkInCard: some View {
        VStack(spacing: 12) {
            Button {
                showingConfirmation = true
            } label: {
                Label("Check In Now", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(!viewModel.isEnabled)
            .accessibilityLabel("Confirm check-in")

            if let lastCheckIn = viewModel.lastCheckInDate {
                Text("Last check-in: \(lastCheckIn, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Settings

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)

            Toggle("Enable Dead-Man Switch", isOn: $viewModel.isEnabled)

            if viewModel.isEnabled {
                Picker("Check-In Interval", selection: $viewModel.checkInInterval) {
                    ForEach(CheckInInterval.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Escalation Info

    private var escalationInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Escalation Sequence")
                .font(.headline)

            escalationStep(number: 1, title: "Missed Check-In", description: "Push notification reminder sent")
            escalationStep(number: 2, title: "24 Hours Later", description: "SMS reminder sent to your phone")
            escalationStep(number: 3, title: "48 Hours Later", description: "Email notification sent")
            escalationStep(number: 4, title: "72 Hours Later", description: "Trusted contacts notified")
            escalationStep(number: 5, title: "7 Days Later", description: "Succession plan triggered")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func escalationStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(Color.blue.opacity(0.15), in: Circle())
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

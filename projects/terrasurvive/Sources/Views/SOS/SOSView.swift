import SwiftUI

// MARK: - SOS View

struct SOSView: View {
    @Environment(SurvivalService.self) private var service
    @Environment(LocationManager.self) private var locationManager

    @State private var isPulsing = false
    @State private var showCreateBeacon = false
    @State private var sosMessage = "SOS — Emergency assistance needed"
    @State private var selectedCountry = "United States"
    @State private var showBeaconHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TSTheme.Spacing.xl) {
                    // GPS Status
                    gpsStatusCard

                    // SOS Button
                    sosButton

                    // Emergency Contacts
                    emergencyContactsSection

                    // Beacon History
                    beaconHistorySection
                }
                .padding(.vertical, TSTheme.Spacing.lg)
            }
            .background(TSTheme.background)
            .navigationTitle("SOS Beacon")
            .tsNavigationStyle()
            .sheet(isPresented: $showCreateBeacon) {
                CreateBeaconSheet(
                    sosMessage: $sosMessage,
                    onSend: createBeacon
                )
                .presentationDetents([.medium])
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.startUpdating()
            }
        }
    }

    // MARK: - GPS Status Card

    private var gpsStatusCard: some View {
        VStack(spacing: TSTheme.Spacing.md) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(locationManager.isAuthorized ? TSTheme.accentGreen : TSTheme.danger)

                Text("GPS Status")
                    .font(TSTheme.Font.subheading(16))
                    .foregroundStyle(TSTheme.textPrimary)

                Spacer()

                HStack(spacing: TSTheme.Spacing.xs) {
                    Circle()
                        .fill(locationManager.isAuthorized ? TSTheme.accentGreen : TSTheme.danger)
                        .frame(width: 8, height: 8)
                    Text(locationManager.isAuthorized ? "Active" : "Unavailable")
                        .font(TSTheme.Font.caption(12))
                        .foregroundStyle(locationManager.isAuthorized ? TSTheme.accentGreen : TSTheme.danger)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                    Text("Coordinates")
                        .font(TSTheme.Font.caption(11))
                        .foregroundStyle(TSTheme.textTertiary)
                    Text(locationManager.coordinateString)
                        .font(TSTheme.Font.mono(16))
                        .foregroundStyle(TSTheme.textPrimary)
                }
                Spacer()
                if let loc = locationManager.location {
                    VStack(alignment: .trailing, spacing: TSTheme.Spacing.xs) {
                        Text("Altitude")
                            .font(TSTheme.Font.caption(11))
                            .foregroundStyle(TSTheme.textTertiary)
                        Text(String(format: "%.0f m", loc.altitude))
                            .font(TSTheme.Font.mono(16))
                            .foregroundStyle(TSTheme.textPrimary)
                    }
                }
            }
        }
        .tsCard()
        .padding(.horizontal, TSTheme.Spacing.lg)
    }

    // MARK: - SOS Button

    private var sosButton: some View {
        VStack(spacing: TSTheme.Spacing.md) {
            Button {
                showCreateBeacon = true
            } label: {
                ZStack {
                    // Outer pulse
                    Circle()
                        .fill(TSTheme.danger.opacity(0.15))
                        .frame(width: 180, height: 180)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: isPulsing
                        )

                    // Middle ring
                    Circle()
                        .fill(TSTheme.danger.opacity(0.3))
                        .frame(width: 150, height: 150)

                    // Inner button
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [TSTheme.danger, TSTheme.danger.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: TSTheme.danger.opacity(0.5), radius: 20)

                    VStack(spacing: TSTheme.Spacing.xs) {
                        Image(systemName: "sos")
                            .font(.system(size: 32, weight: .heavy))
                        Text("SEND")
                            .font(TSTheme.Font.caption(12))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .onAppear { isPulsing = true }

            Text("Tap to create an SOS beacon with your GPS coordinates")
                .font(TSTheme.Font.caption(12))
                .foregroundStyle(TSTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Emergency Contacts

    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(icon: "phone.fill", title: "Emergency Contacts")

            // Country picker
            Picker("Country", selection: $selectedCountry) {
                ForEach(service.emergencyContacts) { contact in
                    Text(contact.country).tag(contact.country)
                }
            }
            .pickerStyle(.menu)
            .tint(TSTheme.accentOrange)
            .padding(.horizontal, TSTheme.Spacing.lg)

            if let contact = service.contactsForCountry(selectedCountry) {
                VStack(spacing: TSTheme.Spacing.sm) {
                    emergencyRow(label: "Universal Emergency", number: contact.universalEmergency, color: TSTheme.danger)
                    emergencyRow(label: "Police", number: contact.police, color: TSTheme.waterBlue)
                    emergencyRow(label: "Fire", number: contact.fire, color: TSTheme.fire)
                    emergencyRow(label: "Ambulance", number: contact.ambulance, color: TSTheme.accentGreen)

                    if let coastGuard = contact.coastGuard {
                        emergencyRow(label: "Coast Guard", number: coastGuard, color: TSTheme.water)
                    }
                    if let mountainRescue = contact.mountainRescue {
                        emergencyRow(label: "Mountain Rescue", number: mountainRescue, color: TSTheme.sandBrown)
                    }
                }
                .tsCard()
                .padding(.horizontal, TSTheme.Spacing.lg)
            }
        }
    }

    private func emergencyRow(label: String, number: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(TSTheme.Font.body(14))
                .foregroundStyle(TSTheme.textSecondary)
            Spacer()
            Text(number)
                .font(TSTheme.Font.mono(16))
                .foregroundStyle(TSTheme.textPrimary)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Beacon History

    private var beaconHistorySection: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            TSSectionHeader(
                icon: "antenna.radiowaves.left.and.right",
                title: "Beacon History",
                count: service.sosBeacons.count
            )

            if service.sosBeacons.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: TSTheme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(TSTheme.accentGreen)
                        Text("No active beacons")
                            .font(TSTheme.Font.caption())
                            .foregroundStyle(TSTheme.textTertiary)
                    }
                    .padding(.vertical, TSTheme.Spacing.lg)
                    Spacer()
                }
            } else {
                LazyVStack(spacing: TSTheme.Spacing.sm) {
                    ForEach(service.sosBeacons) { beacon in
                        BeaconCard(
                            beacon: beacon,
                            onMarkSent: { service.markBeaconSent(beacon) },
                            onDelete: { service.deleteBeacon(beacon) }
                        )
                    }
                }
                .padding(.horizontal, TSTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Actions

    private func createBeacon() {
        service.createBeacon(
            latitude: locationManager.latitude,
            longitude: locationManager.longitude,
            message: sosMessage
        )
        sosMessage = "SOS — Emergency assistance needed"
        showCreateBeacon = false
    }
}

// MARK: - Create Beacon Sheet

struct CreateBeaconSheet: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss
    @Binding var sosMessage: String
    let onSend: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: TSTheme.Spacing.lg) {
                Image(systemName: "sos")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(TSTheme.danger)

                Text("Create SOS Beacon")
                    .font(TSTheme.Font.heading())
                    .foregroundStyle(TSTheme.textPrimary)

                VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                    Text("Location")
                        .font(TSTheme.Font.caption())
                        .foregroundStyle(TSTheme.textTertiary)
                    Text(locationManager.coordinateString)
                        .font(TSTheme.Font.mono(16))
                        .foregroundStyle(TSTheme.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .tsCard()

                VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                    Text("Message")
                        .font(TSTheme.Font.caption())
                        .foregroundStyle(TSTheme.textTertiary)
                    TextField("SOS message...", text: $sosMessage, axis: .vertical)
                        .font(TSTheme.Font.body())
                        .foregroundStyle(TSTheme.textPrimary)
                        .lineLimit(3...5)
                        .padding(TSTheme.Spacing.md)
                        .background(TSTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.sm))
                }

                Button(action: onSend) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        Text("SEND SOS BEACON")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TSTheme.Spacing.md)
                    .background(TSTheme.danger)
                    .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.md))
                }

                Spacer()
            }
            .padding(TSTheme.Spacing.xl)
            .background(TSTheme.background)
            .toolbar {
                ToolbarItem(placement: .tsTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TSTheme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Beacon Card

struct BeaconCard: View {
    let beacon: SOSBeacon
    let onMarkSent: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: TSTheme.Spacing.md) {
            HStack {
                Image(systemName: beacon.isSent ? "checkmark.circle.fill" : "antenna.radiowaves.left.and.right")
                    .foregroundStyle(beacon.isSent ? TSTheme.accentGreen : TSTheme.danger)

                Text(beacon.coordinateString)
                    .font(TSTheme.Font.mono(13))
                    .foregroundStyle(TSTheme.textPrimary)

                Spacer()

                Text(beacon.timestamp, style: .relative)
                    .font(TSTheme.Font.caption(11))
                    .foregroundStyle(TSTheme.textTertiary)
            }

            Text(beacon.message)
                .font(TSTheme.Font.body(13))
                .foregroundStyle(TSTheme.textSecondary)
                .lineLimit(2)

            HStack(spacing: TSTheme.Spacing.md) {
                if !beacon.isSent {
                    Button(action: onMarkSent) {
                        HStack(spacing: TSTheme.Spacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                            Text("Mark Sent")
                                .font(TSTheme.Font.caption(12))
                        }
                        .foregroundStyle(TSTheme.accentGreen)
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    HStack(spacing: TSTheme.Spacing.xs) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Delete")
                            .font(TSTheme.Font.caption(12))
                    }
                    .foregroundStyle(TSTheme.danger)
                }
            }
        }
        .tsCard(padding: TSTheme.Spacing.md)
    }
}

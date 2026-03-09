import SwiftUI

struct IntelligenceTab: View {
    @Environment(DataOrchestrator.self) private var data
    @State private var selectedSection: IntelSection = .brief

    enum IntelSection: String, CaseIterable {
        case brief = "World Brief"
        case rfSensing = "RF Sensing"
        case maxar = "Satellite Imagery"
        case satellites = "Satellite Tracker"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Section Picker
                    Picker("Section", selection: $selectedSection) {
                        ForEach(IntelSection.allCases, id: \.self) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    switch selectedSection {
                    case .brief:
                        WorldBriefView()
                    case .rfSensing:
                        RFSensingView()
                    case .maxar:
                        MaxarEventListView()
                    case .satellites:
                        SatelliteListView()
                    }
                }
            }
            .navigationTitle("Intelligence")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - World Brief View
struct WorldBriefView: View {
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        ScrollView {
            if let brief = data.worldBrief {
                VStack(alignment: .leading, spacing: 16) {
                    // Threat Level Banner
                    HStack {
                        VStack(alignment: .leading) {
                            Text("GLOBAL THREAT ASSESSMENT")
                                .font(NETheme.mono(10))
                                .foregroundStyle(NETheme.textTertiary)
                            Text(brief.title)
                                .font(NETheme.heading(20))
                                .foregroundStyle(NETheme.textPrimary)
                        }
                        Spacer()
                        SeverityBadge(level: brief.globalThreatLevel)
                    }
                    .padding()
                    .glassCard()

                    // Summary
                    Text(brief.summary)
                        .font(NETheme.body())
                        .foregroundStyle(NETheme.textSecondary)
                        .padding(.horizontal)

                    // Events
                    ForEach(brief.events) { event in
                        BriefEventCard(event: event)
                    }

                    // Generation time
                    HStack {
                        Image(systemName: "clock")
                        Text("Generated \(brief.generatedAt.formatted(.relative(presentation: .named)))")
                    }
                    .font(NETheme.caption())
                    .foregroundStyle(NETheme.textTertiary)
                    .padding(.horizontal)
                }
                .padding()
            } else {
                ContentUnavailableView("Loading Brief...", systemImage: "brain.head.profile", description: Text("Analyzing global intelligence feeds"))
            }
        }
    }
}

struct BriefEventCard: View {
    let event: BriefEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: event.category.icon)
                    .foregroundStyle(Color(hex: event.severity.colorHex))
                Text(event.category.rawValue.uppercased())
                    .font(NETheme.mono(10))
                    .foregroundStyle(NETheme.textTertiary)
                Spacer()
                SeverityBadge(level: event.severity)
            }

            Text(event.headline)
                .font(NETheme.subheading(15))
                .foregroundStyle(NETheme.textPrimary)

            Text(event.description)
                .font(NETheme.body(13))
                .foregroundStyle(NETheme.textSecondary)

            HStack {
                Image(systemName: "mappin")
                Text(event.region)
                Spacer()
                Text(event.timestamp.formatted(.relative(presentation: .named)))
            }
            .font(NETheme.caption())
            .foregroundStyle(NETheme.textTertiary)
        }
        .padding()
        .glassCard()
        .padding(.horizontal)
    }
}

// MARK: - Maxar Satellite Events
struct MaxarEventListView: View {
    @Environment(DataOrchestrator.self) private var data

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                Text("Maxar Open Satellite Imagery")
                    .font(NETheme.subheading(14))
                    .foregroundStyle(NETheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                Text("28 disaster events with high-resolution satellite imagery from 4 satellites (GeoEye-1, WorldView-2/3/4) spanning 2010-2023.")
                    .font(NETheme.body(12))
                    .foregroundStyle(NETheme.textSecondary)
                    .padding(.horizontal)

                ForEach(data.maxarEvents) { event in
                    MaxarEventCard(event: event)
                }
            }
            .padding(.vertical)
        }
    }
}

struct MaxarEventCard: View {
    let event: MaxarEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.icon)
                .font(.system(size: 20))
                .foregroundStyle(NETheme.accent)
                .frame(width: 44, height: 44)
                .background(NETheme.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(NETheme.subheading(14))
                    .foregroundStyle(NETheme.textPrimary)
                HStack(spacing: 8) {
                    Label(event.eventType, systemImage: "tag")
                    if event.coordinate != nil {
                        Label("Geolocated", systemImage: "mappin")
                    }
                }
                .font(NETheme.caption())
                .foregroundStyle(NETheme.textTertiary)
            }

            Spacer()

            Image(systemName: "photo.artframe")
                .foregroundStyle(NETheme.textTertiary)
        }
        .padding()
        .glassCard()
        .padding(.horizontal)
    }
}

// MARK: - Satellite List
struct SatelliteListView: View {
    @Environment(DataOrchestrator.self) private var data
    @State private var selectedGroup: SatelliteGroup = .stations

    var body: some View {
        VStack(spacing: 0) {
            // Group picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SatelliteGroup.allCases) { group in
                        Button {
                            selectedGroup = group
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: group.icon)
                                Text(group.displayName)
                            }
                            .font(NETheme.caption())
                            .foregroundStyle(selectedGroup == group ? .white : NETheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedGroup == group ? Color(hex: group.color) : NETheme.surfaceOverlay)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            // Satellite list
            ScrollView {
                LazyVStack(spacing: 8) {
                    let filtered = data.satellites.filter { $0.group == selectedGroup || selectedGroup == .active }
                    ForEach(filtered.prefix(100), id: \.id) { sat in
                        SatelliteRow(satellite: sat)
                    }
                    if filtered.isEmpty {
                        ContentUnavailableView("No Satellites", systemImage: "satellite", description: Text("Loading \(selectedGroup.displayName) data..."))
                    }
                }
                .padding()
            }
        }
    }
}

struct SatelliteRow: View {
    let satellite: SatellitePosition

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: satellite.group.icon)
                .foregroundStyle(Color(hex: satellite.group.color))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(satellite.name)
                    .font(NETheme.body(13))
                    .foregroundStyle(NETheme.textPrimary)
                    .lineLimit(1)
                Text("NORAD \(satellite.id)")
                    .font(NETheme.mono(10))
                    .foregroundStyle(NETheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(satellite.altitudeFormatted)
                    .font(NETheme.mono(11))
                    .foregroundStyle(NETheme.accent)
                Text(String(format: "%.1f km/s", satellite.velocity))
                    .font(NETheme.mono(10))
                    .foregroundStyle(NETheme.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 10)
    }
}

import SwiftUI

struct SettingsTab: View {
    @Environment(AppState.self) private var appState
    @Environment(DataOrchestrator.self) private var data
    @State private var notificationsEnabled = true
    @State private var autoRefresh = true
    @State private var refreshInterval = 15

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                List {
                    // Data Feeds Status
                    Section {
                        HStack {
                            Text("Active Feeds")
                            Spacer()
                            Text("\(data.activeFeedCount)")
                                .foregroundStyle(NETheme.accent)
                        }
                        HStack {
                            Text("Last Refresh")
                            Spacer()
                            DataFreshnessPill(lastUpdate: data.lastRefresh)
                        }
                        if !data.errors.isEmpty {
                            DisclosureGroup("Errors (\(data.errors.count))") {
                                ForEach(data.errors, id: \.self) { error in
                                    Text(error)
                                        .font(NETheme.caption())
                                        .foregroundStyle(NETheme.severityCritical)
                                }
                            }
                        }
                        Button {
                            Task { await data.startAllFeeds() }
                        } label: {
                            Label("Refresh All Feeds", systemImage: "arrow.clockwise")
                                .foregroundStyle(NETheme.accent)
                        }
                    } header: {
                        Text("Data Sources")
                    }

                    // Notifications
                    Section {
                        Toggle("Push Notifications", isOn: $notificationsEnabled)
                        Toggle("Auto-Refresh", isOn: $autoRefresh)
                        if autoRefresh {
                            Picker("Interval", selection: $refreshInterval) {
                                Text("5 min").tag(5)
                                Text("15 min").tag(15)
                                Text("30 min").tag(30)
                                Text("60 min").tag(60)
                            }
                        }
                    } header: {
                        Text("Notifications & Refresh")
                    }

                    // Data Layer Defaults
                    Section {
                        Button("Reset to Defaults") {
                            appState.activeDataLayers = [.earthquakes, .wildfires, .weather, .satellites, .news]
                        }
                        Button("Enable All Layers") {
                            appState.activeDataLayers = Set(DataLayerType.allCases)
                        }
                    } header: {
                        Text("Layer Presets")
                    }

                    // API Info
                    Section {
                        InfoRow(label: "Weather", value: "Open-Meteo (free)")
                        InfoRow(label: "Earthquakes", value: "USGS (free)")
                        InfoRow(label: "Satellites", value: "CelesTrak (free)")
                        InfoRow(label: "Fires", value: "NASA FIRMS (free)")
                        InfoRow(label: "Flights", value: "OpenSky (free)")
                        InfoRow(label: "Radar", value: "RainViewer (free)")
                        InfoRow(label: "Live TV", value: "IPTV-org (free)")
                        InfoRow(label: "Imagery", value: "Maxar STAC (free)")
                        InfoRow(label: "Geocoding", value: "Open-Meteo (free)")
                    } header: {
                        Text("Intelligence Feeds (All Free)")
                    }

                    Section {
                        InfoRow(label: "House Trades", value: "House Stock Watcher (free)")
                        InfoRow(label: "Senate Trades", value: "Senate Stock Watcher (free)")
                        InfoRow(label: "Contracts", value: "USASpending.gov (free)")
                        InfoRow(label: "Lobbying", value: "LDA Senate (free)")
                        InfoRow(label: "National Debt", value: "Treasury Fiscal Data (free)")
                        InfoRow(label: "Job Openings", value: "BLS JOLTS (free)")
                    } header: {
                        Text("Capital Flow Feeds (All Free)")
                    }

                    // About
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(NETheme.textTertiary)
                        }
                        HStack {
                            Text("Data Layers")
                            Spacer()
                            Text("\(DataLayerType.allCases.count)")
                                .foregroundStyle(NETheme.textTertiary)
                        }
                    } header: {
                        Text("About Nighteye")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(NETheme.caption())
                .foregroundStyle(NETheme.textTertiary)
        }
    }
}

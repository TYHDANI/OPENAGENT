import SwiftUI
import MapKit

// MARK: - Map View

struct MapView: View {
    @Environment(SurvivalService.self) private var service
    @Environment(LocationManager.self) private var locationManager

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    )
    @State private var selectedAnnotation: MapAnnotationItem?
    @State private var showRegionPicker = false
    @State private var mapStyle: MapStyleOption = .standard

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapContent

                VStack(spacing: TSTheme.Spacing.sm) {
                    mapControls
                    coordinateBar
                }
                .padding(.horizontal, TSTheme.Spacing.lg)
                .padding(.bottom, TSTheme.Spacing.sm)
            }
            .navigationTitle("TerraSurvive")
            .tsNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .tsLeading) {
                    mapStyleButton
                }
                ToolbarItem(placement: .tsTrailing) {
                    regionPickerButton
                }
            }
            .sheet(isPresented: $showRegionPicker) {
                RegionPickerSheet(cameraPosition: $cameraPosition)
            }
            .sheet(item: $selectedAnnotation) { annotation in
                AnnotationDetailSheet(annotation: annotation)
                    .presentationDetents([.medium])
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map(position: $cameraPosition) {
            // User location
            UserAnnotation()

            // Annotations
            ForEach(service.annotations) { annotation in
                Annotation(annotation.title, coordinate: annotation.coordinate) {
                    Button {
                        selectedAnnotation = annotation
                    } label: {
                        Image(systemName: annotation.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(annotation.color)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    }
                }
            }

            // Region circles
            ForEach(service.regions) { region in
                MapCircle(center: region.coordinate, radius: region.radiusKm * 1000)
                    .foregroundStyle(region.biome.color.opacity(0.1))
                    .stroke(region.biome.color.opacity(0.4), lineWidth: 2)
            }
        }
        .mapStyle(mapStyle.style)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Map Controls

    private var mapControls: some View {
        HStack {
            Spacer()
            VStack(spacing: TSTheme.Spacing.sm) {
                Button {
                    centerOnUser()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(TSTheme.waterBlue)
                        .frame(width: 40, height: 40)
                        .background(TSTheme.surface.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.sm))
                }

                Button {
                    cycleMapStyle()
                } label: {
                    Image(systemName: mapStyle.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(TSTheme.accentOrange)
                        .frame(width: 40, height: 40)
                        .background(TSTheme.surface.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.sm))
                }
            }
        }
    }

    // MARK: - Coordinate Bar

    private var coordinateBar: some View {
        HStack(spacing: TSTheme.Spacing.md) {
            Image(systemName: "location.circle.fill")
                .foregroundStyle(TSTheme.accentGreen)
            Text(locationManager.coordinateString)
                .font(TSTheme.Font.mono(13))
                .foregroundStyle(TSTheme.textPrimary)
            Spacer()
            if locationManager.isAuthorized {
                Circle()
                    .fill(TSTheme.accentGreen)
                    .frame(width: 8, height: 8)
                Text("GPS")
                    .font(TSTheme.Font.caption(11))
                    .foregroundStyle(TSTheme.textSecondary)
            }
        }
        .padding(TSTheme.Spacing.md)
        .background(TSTheme.surface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: TSTheme.Radius.md))
    }

    // MARK: - Toolbar Buttons

    private var mapStyleButton: some View {
        Button {
            cycleMapStyle()
        } label: {
            Image(systemName: "map")
                .foregroundStyle(TSTheme.textSecondary)
        }
    }

    private var regionPickerButton: some View {
        Button {
            showRegionPicker = true
        } label: {
            Image(systemName: "globe.americas.fill")
                .foregroundStyle(TSTheme.accentOrange)
        }
    }

    // MARK: - Actions

    private func centerOnUser() {
        if let location = locationManager.location {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }

    private func cycleMapStyle() {
        let allStyles = MapStyleOption.allCases
        if let index = allStyles.firstIndex(of: mapStyle) {
            mapStyle = allStyles[(index + 1) % allStyles.count]
        }
    }
}

// MARK: - Map Style Option

enum MapStyleOption: String, CaseIterable {
    case standard
    case satellite
    case hybrid

    var style: MapStyle {
        switch self {
        case .standard: return .standard(elevation: .realistic)
        case .satellite: return .imagery(elevation: .realistic)
        case .hybrid: return .hybrid(elevation: .realistic)
        }
    }

    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas.fill"
        case .hybrid: return "square.2.layers.3d"
        }
    }
}

// MARK: - Region Picker Sheet

struct RegionPickerSheet: View {
    @Environment(SurvivalService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        NavigationStack {
            List {
                ForEach(service.regions) { region in
                    Button {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: region.coordinate,
                                span: MKCoordinateSpan(
                                    latitudeDelta: region.radiusKm / 50,
                                    longitudeDelta: region.radiusKm / 50
                                )
                            )
                        )
                        dismiss()
                    } label: {
                        HStack(spacing: TSTheme.Spacing.md) {
                            Image(systemName: region.biome.icon)
                                .foregroundStyle(region.biome.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: TSTheme.Spacing.xs) {
                                Text(region.name)
                                    .font(TSTheme.Font.subheading(16))
                                    .foregroundStyle(TSTheme.textPrimary)
                                Text(region.biome.rawValue)
                                    .font(TSTheme.Font.caption())
                                    .foregroundStyle(TSTheme.textSecondary)
                            }

                            Spacer()

                            if region.isDownloaded {
                                Image(systemName: "checkmark.icloud.fill")
                                    .foregroundStyle(TSTheme.accentGreen)
                            } else {
                                Text("\(region.downloadSizeMB) MB")
                                    .font(TSTheme.Font.caption(11))
                                    .foregroundStyle(TSTheme.textTertiary)
                            }
                        }
                        .padding(.vertical, TSTheme.Spacing.xs)
                    }
                }
                .listRowBackground(TSTheme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(TSTheme.background)
            .navigationTitle("Regions")
            .tsNavigationStyle()
            .toolbar {
                ToolbarItem(placement: .tsTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TSTheme.accentOrange)
                }
            }
        }
    }
}

// MARK: - Annotation Detail Sheet

struct AnnotationDetailSheet: View {
    let annotation: MapAnnotationItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: TSTheme.Spacing.lg) {
                Image(systemName: annotation.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(annotation.color)

                Text(annotation.title)
                    .font(TSTheme.Font.heading())
                    .foregroundStyle(TSTheme.textPrimary)

                Text(annotation.kind.rawValue)
                    .font(TSTheme.Font.caption())
                    .foregroundStyle(TSTheme.textSecondary)

                VStack(spacing: TSTheme.Spacing.sm) {
                    HStack {
                        Text("Latitude")
                            .font(TSTheme.Font.caption())
                            .foregroundStyle(TSTheme.textTertiary)
                        Spacer()
                        Text(String(format: "%.4f", annotation.coordinate.latitude))
                            .font(TSTheme.Font.mono())
                            .foregroundStyle(TSTheme.textPrimary)
                    }
                    HStack {
                        Text("Longitude")
                            .font(TSTheme.Font.caption())
                            .foregroundStyle(TSTheme.textTertiary)
                        Spacer()
                        Text(String(format: "%.4f", annotation.coordinate.longitude))
                            .font(TSTheme.Font.mono())
                            .foregroundStyle(TSTheme.textPrimary)
                    }
                }
                .tsCard()

                Spacer()
            }
            .padding(TSTheme.Spacing.xl)
            .background(TSTheme.background)
            .toolbar {
                ToolbarItem(placement: .tsTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TSTheme.accentOrange)
                }
            }
        }
    }
}

import SwiftUI

struct LayerPanelView: View {
    @Environment(AppState.self) private var appState
    @State private var expandedCategories: Set<LayerCategory> = Set(LayerCategory.allCases)

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Data Layers")
                    .font(NETheme.heading(18))
                    .foregroundStyle(NETheme.textPrimary)
                Spacer()
                Text("\(state.activeDataLayers.count) active")
                    .font(NETheme.caption())
                    .foregroundStyle(NETheme.accent)
                Button {
                    withAnimation { state.showLayerPanel = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(NETheme.textSecondary)
                }
            }
            .padding()

            Divider().background(NETheme.border)

            // Layer categories
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(LayerCategory.allCases) { category in
                        VStack(spacing: 0) {
                            // Category header
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    if expandedCategories.contains(category) {
                                        expandedCategories.remove(category)
                                    } else {
                                        expandedCategories.insert(category)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 14))
                                        .foregroundStyle(NETheme.accent)
                                        .frame(width: 24)
                                    Text(category.rawValue)
                                        .font(NETheme.subheading(14))
                                        .foregroundStyle(NETheme.textPrimary)
                                    Spacer()
                                    let count = layersForCategory(category).filter { state.activeDataLayers.contains($0) }.count
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(NETheme.mono(11))
                                            .foregroundStyle(NETheme.accent)
                                    }
                                    Image(systemName: expandedCategories.contains(category) ? "chevron.down" : "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(NETheme.textTertiary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            // Layer toggles
                            if expandedCategories.contains(category) {
                                ForEach(layersForCategory(category)) { layer in
                                    LayerToggle(
                                        layer: layer,
                                        isActive: Binding(
                                            get: { state.activeDataLayers.contains(layer) },
                                            set: { active in
                                                if active { state.activeDataLayers.insert(layer) }
                                                else { state.activeDataLayers.remove(layer) }
                                            }
                                        )
                                    )
                                    .padding(.leading, 24)
                                }
                            }

                            Divider().background(NETheme.border).padding(.leading)
                        }
                    }
                }
            }

            // Quick actions
            HStack(spacing: 12) {
                Button("All On") {
                    withAnimation { state.activeDataLayers = Set(DataLayerType.allCases) }
                }
                .font(NETheme.caption())
                .foregroundStyle(NETheme.accent)

                Button("All Off") {
                    withAnimation { state.activeDataLayers = [] }
                }
                .font(NETheme.caption())
                .foregroundStyle(NETheme.severityCritical)

                Spacer()

                Button("Defaults") {
                    withAnimation { state.activeDataLayers = [.earthquakes, .wildfires, .weather, .satellites, .news] }
                }
                .font(NETheme.caption())
                .foregroundStyle(NETheme.textSecondary)
            }
            .padding()
        }
        .frame(width: 300)
        .background(NETheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.4), radius: 20)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding()
    }

    private func layersForCategory(_ category: LayerCategory) -> [DataLayerType] {
        DataLayerType.allCases.filter { $0.category == category }
    }
}

import SwiftUI

/// Garden — Gem art simulation where users can grow and arrange virtual crystals
struct GardenView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var gardenGems: [GardenGem] = GardenGem.defaults
    @State private var selectedGem: GardenGem?
    @State private var showAddSheet = false
    @State private var isGrowing = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color.purple.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Garden Visualization
                        GardenCanvasView(gems: gardenGems, selectedGem: $selectedGem)
                            .frame(height: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                            .padding(.horizontal)

                        // Controls
                        HStack(spacing: 16) {
                            Button {
                                withAnimation(.spring(response: 0.6)) {
                                    isGrowing.toggle()
                                    if isGrowing { startGrowthAnimation() }
                                }
                            } label: {
                                Label(isGrowing ? "Pause" : "Grow", systemImage: isGrowing ? "pause.fill" : "leaf.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(isGrowing ? Color.orange : Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                showAddSheet = true
                            } label: {
                                Label("Add Gem", systemImage: "plus.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal)

                        // Gem Collection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Crystal Collection")
                                .font(.title3.bold())
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(gardenGems) { gem in
                                    GardenGemCard(gem: gem, isSelected: selectedGem?.id == gem.id) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedGem = gem
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Growth Stats
                        if let gem = selectedGem {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Crystal Details")
                                    .font(.headline)

                                HStack(spacing: 16) {
                                    GrowthStat(label: "Size", value: String(format: "%.1f mm", gem.size), icon: "ruler")
                                    GrowthStat(label: "Clarity", value: "\(Int(gem.clarity * 100))%", icon: "sparkle")
                                    GrowthStat(label: "Growth", value: "\(Int(gem.growthProgress * 100))%", icon: "chart.line.uptrend.xyaxis")
                                }

                                // Growth Progress Bar
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Growth Progress")
                                            .font(.caption.bold())
                                        Spacer()
                                        Text("\(Int(gem.growthProgress * 100))%")
                                            .font(.caption.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.secondary.opacity(0.15))
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(gem.gemstone.gardenColor)
                                                .frame(width: geo.size.width * gem.growthProgress)
                                        }
                                    }
                                    .frame(height: 8)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Garden")
            .sheet(isPresented: $showAddSheet) {
                AddGardenGemSheet { newGem in
                    gardenGems.append(newGem)
                }
            }
        }
    }

    private func startGrowthAnimation() {
        Task {
            while isGrowing {
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.easeInOut(duration: 0.5)) {
                    for i in gardenGems.indices {
                        if gardenGems[i].growthProgress < 1.0 {
                            gardenGems[i].growthProgress = min(1.0, gardenGems[i].growthProgress + 0.02)
                            gardenGems[i].size = gardenGems[i].size + 0.05
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Garden Data Model
struct GardenGem: Identifiable {
    let id = UUID()
    let gemstone: GemstoneType
    var size: Double
    var clarity: Double
    var growthProgress: Double
    var position: CGPoint // Relative position in garden (0-1)

    static let defaults: [GardenGem] = [
        GardenGem(gemstone: .redBeryl, size: 2.4, clarity: 0.85, growthProgress: 0.6, position: CGPoint(x: 0.3, y: 0.4)),
        GardenGem(gemstone: .alexandrite, size: 1.8, clarity: 0.92, growthProgress: 0.4, position: CGPoint(x: 0.7, y: 0.3)),
        GardenGem(gemstone: .tanzanite, size: 3.1, clarity: 0.78, growthProgress: 0.8, position: CGPoint(x: 0.5, y: 0.7)),
    ]
}

extension GemstoneType {
    var gardenColor: LinearGradient {
        switch self {
        case .redBeryl: return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .alexandrite: return LinearGradient(colors: [.green, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tanzanite: return LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .paraibaTourmaline: return LinearGradient(colors: [.cyan, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var gardenIcon: String {
        switch self {
        case .redBeryl: return "diamond.fill"
        case .alexandrite: return "sparkle"
        case .tanzanite: return "hexagon.fill"
        case .paraibaTourmaline: return "seal.fill"
        }
    }
}

// MARK: - Garden Canvas
struct GardenCanvasView: View {
    let gems: [GardenGem]
    @Binding var selectedGem: GardenGem?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Soft background
                LinearGradient(
                    colors: [Color.black.opacity(0.03), Color.purple.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Grid pattern
                ForEach(0..<6) { i in
                    ForEach(0..<4) { j in
                        Circle()
                            .fill(Color.secondary.opacity(0.05))
                            .frame(width: 4, height: 4)
                            .position(x: CGFloat(i + 1) * geo.size.width / 7, y: CGFloat(j + 1) * geo.size.height / 5)
                    }
                }

                // Gem crystals
                ForEach(gems) { gem in
                    GardenCrystal(gem: gem, isSelected: selectedGem?.id == gem.id)
                        .position(
                            x: gem.position.x * geo.size.width,
                            y: gem.position.y * geo.size.height
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGem = gem
                            }
                        }
                }
            }
        }
    }
}

struct GardenCrystal: View {
    let gem: GardenGem
    let isSelected: Bool

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(gem.gemstone.gardenColor.opacity(0.2))
                .frame(width: crystalSize * 2, height: crystalSize * 2)
                .blur(radius: 10)

            // Crystal
            Image(systemName: gem.gemstone.gardenIcon)
                .font(.system(size: crystalSize))
                .foregroundStyle(gem.gemstone.gardenColor)
                .shadow(color: crystalShadowColor, radius: 8)
                .scaleEffect(isSelected ? 1.2 : 1.0)

            // Growth ring
            if gem.growthProgress < 1.0 {
                Circle()
                    .trim(from: 0, to: gem.growthProgress)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: crystalSize * 1.5, height: crystalSize * 1.5)
                    .rotationEffect(.degrees(-90))
            }
        }
    }

    private var crystalSize: CGFloat {
        16 + CGFloat(gem.size) * 6
    }

    private var crystalShadowColor: Color {
        switch gem.gemstone {
        case .redBeryl: return .red.opacity(0.5)
        case .alexandrite: return .green.opacity(0.5)
        case .tanzanite: return .blue.opacity(0.5)
        case .paraibaTourmaline: return .cyan.opacity(0.5)
        }
    }
}

// MARK: - Gem Cards
struct GardenGemCard: View {
    let gem: GardenGem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: gem.gemstone.gardenIcon)
                    .font(.system(size: 24))
                    .foregroundStyle(gem.gemstone.gardenColor)

                Text(gem.gemstone.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(String(format: "%.1f mm", gem.size))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.purple.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GrowthStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.purple)
            Text(value)
                .font(.caption.bold().monospaced())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Gem Sheet
struct AddGardenGemSheet: View {
    let onAdd: (GardenGem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedType: GemstoneType = .redBeryl

    var body: some View {
        NavigationStack {
            List {
                ForEach(GemstoneType.allCases, id: \.self) { gem in
                    Button {
                        selectedType = gem
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: gem.gardenIcon)
                                .font(.system(size: 24))
                                .foregroundStyle(gem.gardenColor)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(gem.displayName)
                                    .font(.body.bold())
                                    .foregroundStyle(.primary)
                                Text(gem.chemicalFormula)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedType == gem {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Crystal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Plant") {
                        let newGem = GardenGem(
                            gemstone: selectedType,
                            size: 0.5,
                            clarity: Double.random(in: 0.7...0.95),
                            growthProgress: 0.0,
                            position: CGPoint(x: Double.random(in: 0.2...0.8), y: Double.random(in: 0.2...0.8))
                        )
                        onAdd(newGem)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
}

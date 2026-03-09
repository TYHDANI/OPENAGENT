import SwiftUI

struct GemSearchView: View {
    @State private var searchText = ""
    @State private var selectedCategory: GemstoneCategory = .all
    @State private var selectedGem: GemstoneType?
    @State private var showGemDetail = false

    enum GemstoneCategory: String, CaseIterable {
        case all = "All"
        case beryllium = "Beryllium"
        case corundum = "Corundum"
        case tourmaline = "Tourmaline"
        case other = "Other"
    }

    var filteredGems: [GemstoneType] {
        var gems = GemstoneType.allCases
        if !searchText.isEmpty {
            gems = gems.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
        switch selectedCategory {
        case .all: break
        case .beryllium: gems = gems.filter { $0 == .redBeryl }
        case .corundum: gems = gems.filter { $0 == .alexandrite || $0 == .tanzanite }
        case .tourmaline: gems = gems.filter { $0 == .paraibaTourmaline }
        case .other: break
        }
        return gems
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search gemstones...", text: $searchText)
                            .autocorrectionDisabled()
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Category Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(GemstoneCategory.allCases, id: \.self) { cat in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = cat
                                    }
                                } label: {
                                    Text(cat.rawValue)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(selectedCategory == cat ? .white : .secondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(selectedCategory == cat ? gemGradient : clearGradient)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(Color.secondary.opacity(0.2), lineWidth: selectedCategory == cat ? 0 : 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Featured Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Gemstones")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        // Gem Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            ForEach(filteredGems, id: \.self) { gem in
                                GemCard(gemstone: gem) {
                                    selectedGem = gem
                                    showGemDetail = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Quick Stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Synthesis Quick Facts")
                            .font(.title3.bold())
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            QuickFactCard(icon: "thermometer.high", value: "400-800", unit: "°C", label: "Temp Range")
                            QuickFactCard(icon: "gauge.with.dots.needle.50percent", value: "100-400", unit: "MPa", label: "Pressure")
                            QuickFactCard(icon: "drop.fill", value: "5.0-8.0", unit: "pH", label: "Acidity")
                        }
                        .padding(.horizontal)
                    }

                    // Get Started
                    VStack(spacing: 12) {
                        Text("Ready to Synthesize?")
                            .font(.headline)
                        Text("Select a gemstone above to view parameters and start a Monte Carlo simulation.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [.purple.opacity(0.1), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("GEM OS")
            .sheet(isPresented: $showGemDetail) {
                if let gem = selectedGem {
                    GemDetailSheet(gemstone: gem)
                }
            }
        }
    }

    private var gemGradient: LinearGradient {
        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
    }

    private var clearGradient: LinearGradient {
        LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Gem Card
struct GemCard: View {
    let gemstone: GemstoneType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Gem Visual
                ZStack {
                    Circle()
                        .fill(gemGradient.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: gemIcon)
                        .font(.system(size: 28))
                        .foregroundStyle(gemGradient)
                }

                Text(gemstone.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(gemstone.chemicalFormula)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Difficulty Badge
                Text(difficultyLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(difficultyColor)
                    .clipShape(Capsule())
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var gemIcon: String {
        switch gemstone {
        case .redBeryl: return "diamond.fill"
        case .alexandrite: return "sparkle"
        case .tanzanite: return "hexagon.fill"
        case .paraibaTourmaline: return "seal.fill"
        }
    }

    private var gemGradient: LinearGradient {
        switch gemstone {
        case .redBeryl: return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .alexandrite: return LinearGradient(colors: [.green, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tanzanite: return LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .paraibaTourmaline: return LinearGradient(colors: [.cyan, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var difficultyLabel: String {
        switch gemstone {
        case .redBeryl: return "Intermediate"
        case .alexandrite: return "Expert"
        case .tanzanite: return "Intermediate"
        case .paraibaTourmaline: return "Advanced"
        }
    }

    private var difficultyColor: Color {
        switch gemstone {
        case .redBeryl: return .orange
        case .alexandrite: return .red
        case .tanzanite: return .orange
        case .paraibaTourmaline: return .purple
        }
    }
}

struct QuickFactCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.purple)
            Text(value)
                .font(.caption.bold().monospaced())
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Gem Detail Sheet
struct GemDetailSheet: View {
    let gemstone: GemstoneType
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(gemGradient.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: gemIcon)
                                .font(.system(size: 32))
                                .foregroundStyle(gemGradient)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(gemstone.displayName)
                                .font(.title2.bold())
                            Text(gemstone.chemicalFormula)
                                .font(.subheadline.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    // Parameter Ranges
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Synthesis Parameters")
                            .font(.headline)

                        ParamRangeRow(name: "Temperature", range: gemstone.defaultTemperatureRange, unit: "°C", icon: "thermometer.high")
                        ParamRangeRow(name: "Pressure", range: gemstone.defaultPressureRange, unit: "MPa", icon: "gauge.with.dots.needle.50percent")
                        ParamRangeRow(name: "pH", range: gemstone.defaultPHRange, unit: "", icon: "drop.fill")
                    }

                    // About
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                        Text(gemDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Reactor Compatibility
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reactor Compatibility")
                            .font(.headline)
                        ForEach(compatibilityNotes, id: \.self) { note in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(note)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(gemstone.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var gemIcon: String {
        switch gemstone {
        case .redBeryl: return "diamond.fill"
        case .alexandrite: return "sparkle"
        case .tanzanite: return "hexagon.fill"
        case .paraibaTourmaline: return "seal.fill"
        }
    }

    private var gemGradient: LinearGradient {
        switch gemstone {
        case .redBeryl: return LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .alexandrite: return LinearGradient(colors: [.green, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .tanzanite: return LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .paraibaTourmaline: return LinearGradient(colors: [.cyan, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var gemDescription: String {
        switch gemstone {
        case .redBeryl: return "Red Beryl (Bixbite) is one of the rarest gemstones on Earth. Hydrothermal synthesis at moderate temperatures produces crystals with exceptional color saturation and clarity."
        case .alexandrite: return "Alexandrite is famous for its color-change effect, appearing green in daylight and red under incandescent light. Requires precise chromium doping during synthesis."
        case .tanzanite: return "Tanzanite is a blue-violet variety of zoisite found only in Tanzania. Lab synthesis requires careful vanadium incorporation and controlled cooling."
        case .paraibaTourmaline: return "Paraiba Tourmaline is prized for its neon blue-green color caused by copper. Synthesis requires precise copper concentration in the hydrothermal solution."
        }
    }

    private var compatibilityNotes: [String] {
        switch gemstone {
        case .redBeryl: return [
            "Standard autoclave (500 mL) compatible",
            "Moderate pressure requirements (100-300 MPa)",
            "Standard pH monitoring sufficient",
            "Seed crystal: natural beryl fragment recommended"
        ]
        case .alexandrite: return [
            "High-temperature autoclave required (800°C rated)",
            "Chromium-doped nutrient solution needed",
            "Precise cooling rate control critical for color-change",
            "Platinum liner recommended to prevent contamination"
        ]
        case .tanzanite: return [
            "Standard autoclave compatible",
            "Vanadium oxide nutrient source required",
            "Post-growth heat treatment at 600°C for color enhancement",
            "Slow cooling produces larger crystals"
        ]
        case .paraibaTourmaline: return [
            "Copper-resistant vessel required (gold or platinum liner)",
            "Complex multi-element nutrient charge",
            "Extended growth periods (200+ hours typical)",
            "Temperature stability critical for uniform color"
        ]
        }
    }
}

struct ParamRangeRow: View {
    let name: String
    let range: ClosedRange<Double>
    let unit: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.purple)
                .frame(width: 24)
            Text(name)
                .font(.subheadline)
            Spacer()
            Text("\(Int(range.lowerBound))-\(Int(range.upperBound)) \(unit)")
                .font(.subheadline.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

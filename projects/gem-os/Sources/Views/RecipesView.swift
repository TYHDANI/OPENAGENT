import SwiftUI

struct RecipesView: View {
    @State private var viewModel = RecipesViewModel()
    @State private var showingAddRecipe = false
    @State private var selectedRecipe: Recipe?
    @State private var showingRecipeDetail = false
    @Environment(StoreManager.self) private var storeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Search & Filter
                    SearchFilterBar(viewModel: viewModel)

                    // MARK: - Recipe Grid
                    if viewModel.filteredRecipes.isEmpty {
                        ContentUnavailableView(
                            "No Recipes Found",
                            systemImage: "book.closed",
                            description: Text(viewModel.searchQuery.isEmpty ? "Add your first recipe to get started" : "Try adjusting your search criteria")
                        )
                        .frame(minHeight: 400)
                    } else {
                        RecipeGrid(
                            recipes: viewModel.filteredRecipes,
                            onSelect: { recipe in
                                selectedRecipe = recipe
                                showingRecipeDetail = true
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        showingAddRecipe = true
                    }
                    .disabled(!storeManager.isSubscribed)
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                RecipeEditorView(recipe: nil) { newRecipe in
                    viewModel.addRecipe(newRecipe)
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                RecipeDetailView(
                    recipe: recipe,
                    onUpdate: { updatedRecipe in
                        viewModel.updateRecipe(updatedRecipe)
                    },
                    onDelete: {
                        viewModel.deleteRecipe(recipe)
                        showingRecipeDetail = false
                    },
                    onDuplicate: {
                        viewModel.duplicateRecipe(recipe)
                    }
                )
            }
        }
    }
}

// MARK: - Search Filter Bar

struct SearchFilterBar: View {
    @Bindable var viewModel: RecipesViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search recipes...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color.tertiaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Gemstone filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: viewModel.selectedGemstoneFilter == nil,
                        action: { viewModel.selectedGemstoneFilter = nil }
                    )

                    // Only show Red Beryl and Alexandrite for MVP
                    FilterChip(
                        title: GemstoneType.redBeryl.displayName,
                        isSelected: viewModel.selectedGemstoneFilter == .redBeryl,
                        action: { viewModel.selectedGemstoneFilter = .redBeryl }
                    )

                    FilterChip(
                        title: GemstoneType.alexandrite.displayName,
                        isSelected: viewModel.selectedGemstoneFilter == .alexandrite,
                        action: { viewModel.selectedGemstoneFilter = .alexandrite }
                    )
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.tertiaryGroupedBackground)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Recipe Grid

struct RecipeGrid: View {
    let recipes: [Recipe]
    let onSelect: (Recipe) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
            ForEach(recipes) { recipe in
                RecipeCard(recipe: recipe, onSelect: onSelect)
            }
        }
    }
}

// MARK: - Recipe Card

struct RecipeCard: View {
    let recipe: Recipe
    let onSelect: (Recipe) -> Void

    var body: some View {
        Button(action: { onSelect(recipe) }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(recipe.gemstoneType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    DifficultyBadge(difficulty: recipe.difficulty)
                }

                // Description
                Text(recipe.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        RecipeStat(
                            icon: "scalemass",
                            value: String(format: "%.1f-%.1f g", recipe.expectedYield.lowerBound, recipe.expectedYield.upperBound)
                        )
                        RecipeStat(
                            icon: "star.fill",
                            value: String(format: "%.0f%%", recipe.expectedQuality.upperBound * 100)
                        )
                    }
                    HStack(spacing: 16) {
                        RecipeStat(
                            icon: "clock",
                            value: "\(Int(recipe.parameters.duration))h"
                        )
                        RecipeStat(
                            icon: "thermometer",
                            value: "\(Int(recipe.parameters.temperature))°C"
                        )
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: Recipe.Difficulty

    private var badgeColor: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .yellow
        case .advanced: return .orange
        case .expert: return .red
        }
    }

    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }
}

// MARK: - Recipe Stat

struct RecipeStat: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Recipe Detail View

struct RecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    let recipe: Recipe
    let onUpdate: (Recipe) -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.gemstoneType.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(recipe.name)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            DifficultyBadge(difficulty: recipe.difficulty)
                        }

                        Text(recipe.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    // Expected Results
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Expected Results", systemImage: "chart.bar")
                            .font(.headline)

                        HStack(spacing: 20) {
                            ResultMetric(
                                title: "Yield",
                                value: String(format: "%.1f-%.1f g", recipe.expectedYield.lowerBound, recipe.expectedYield.upperBound),
                                icon: "scalemass"
                            )
                            ResultMetric(
                                title: "Quality",
                                value: String(format: "%.0f-%.0f%%", recipe.expectedQuality.lowerBound * 100, recipe.expectedQuality.upperBound * 100),
                                icon: "star.fill"
                            )
                        }
                    }

                    // Parameters
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Synthesis Parameters", systemImage: "slider.horizontal.3")
                            .font(.headline)

                        ParametersList(parameters: recipe.parameters)
                    }

                    // Notes
                    if !recipe.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)

                            Text(recipe.notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            // This will be handled by navigation in ContentView
                            dismiss()
                        }) {
                            Label("Run Simulation", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        HStack(spacing: 12) {
                            Button(action: { showingEditor = true }) {
                                Label("Edit", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(!storeManager.isSubscribed)

                            Button(action: { onDuplicate() }) {
                                Label("Duplicate", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(!storeManager.isSubscribed)

                            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                                Label("Delete", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(Recipe.defaultRecipes.contains(where: { $0.id == recipe.id }))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recipe Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                RecipeEditorView(recipe: recipe) { updatedRecipe in
                    onUpdate(updatedRecipe)
                }
            }
            .alert("Delete Recipe", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Are you sure you want to delete this recipe? This action cannot be undone.")
            }
        }
    }
}

// MARK: - Result Metric

struct ResultMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.tertiaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Parameters List

struct ParametersList: View {
    let parameters: SynthesisParameters

    var body: some View {
        VStack(spacing: 8) {
            ParameterRow(label: "Temperature", value: "\(Int(parameters.temperature))°C")
            ParameterRow(label: "Pressure", value: "\(Int(parameters.pressure)) MPa")
            ParameterRow(label: "pH", value: String(format: "%.1f", parameters.pH))
            ParameterRow(label: "Duration", value: "\(Int(parameters.duration)) hours")
            ParameterRow(label: "Seed Crystal", value: String(format: "%.1f mm", parameters.seedCrystalSize))
            ParameterRow(label: "Nutrient Conc.", value: String(format: "%.2f mol/L", parameters.nutrientConcentration))
            ParameterRow(label: "Cooling Rate", value: String(format: "%.1f°C/h", parameters.coolingRate))
        }
        .padding()
        .background(Color.tertiaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Parameter Row

struct ParameterRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Recipe Editor View

struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var gemstoneType: GemstoneType
    @State private var parameters: SynthesisParameters
    @State private var difficulty: Recipe.Difficulty
    @State private var notes: String
    @State private var expectedYieldLower: Double
    @State private var expectedYieldUpper: Double
    @State private var expectedQualityLower: Double
    @State private var expectedQualityUpper: Double

    let recipe: Recipe?
    let onSave: (Recipe) -> Void

    init(recipe: Recipe?, onSave: @escaping (Recipe) -> Void) {
        self.recipe = recipe
        self.onSave = onSave

        // Initialize state
        _name = State(initialValue: recipe?.name ?? "")
        _description = State(initialValue: recipe?.description ?? "")
        _gemstoneType = State(initialValue: recipe?.gemstoneType ?? .redBeryl)
        _parameters = State(initialValue: recipe?.parameters ?? SynthesisParameters(gemstoneType: .redBeryl))
        _difficulty = State(initialValue: recipe?.difficulty ?? .intermediate)
        _notes = State(initialValue: recipe?.notes ?? "")
        _expectedYieldLower = State(initialValue: recipe?.expectedYield.lowerBound ?? 0.5)
        _expectedYieldUpper = State(initialValue: recipe?.expectedYield.upperBound ?? 1.5)
        _expectedQualityLower = State(initialValue: recipe?.expectedQuality.lowerBound ?? 0.7)
        _expectedQualityUpper = State(initialValue: recipe?.expectedQuality.upperBound ?? 0.9)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Recipe Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Gemstone Type", selection: $gemstoneType) {
                        Text(GemstoneType.redBeryl.displayName).tag(GemstoneType.redBeryl)
                        Text(GemstoneType.alexandrite.displayName).tag(GemstoneType.alexandrite)
                    }
                    .onChange(of: gemstoneType) { _, newValue in
                        parameters.gemstoneType = newValue
                    }

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Recipe.Difficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue).tag(diff)
                        }
                    }
                }

                Section("Expected Results") {
                    VStack(alignment: .leading) {
                        Text("Yield Range (g)")
                        HStack {
                            TextField("Min", value: $expectedYieldLower, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                            Text("-")
                            TextField("Max", value: $expectedYieldUpper, format: .number.precision(.fractionLength(1)))
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Quality Range (%)")
                        HStack {
                            TextField("Min", value: Binding(
                                get: { expectedQualityLower * 100 },
                                set: { expectedQualityLower = $0 / 100 }
                            ), format: .number.precision(.fractionLength(0)))
                                .textFieldStyle(.roundedBorder)
                            Text("-")
                            TextField("Max", value: Binding(
                                get: { expectedQualityUpper * 100 },
                                set: { expectedQualityUpper = $0 / 100 }
                            ), format: .number.precision(.fractionLength(0)))
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                Section("Synthesis Parameters") {
                    LabeledContent("Temperature (°C)") {
                        TextField("Temperature", value: $parameters.temperature, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    LabeledContent("Pressure (MPa)") {
                        TextField("Pressure", value: $parameters.pressure, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    LabeledContent("pH") {
                        TextField("pH", value: $parameters.pH, format: .number.precision(.fractionLength(1)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }

                    LabeledContent("Duration (hours)") {
                        TextField("Duration", value: $parameters.duration, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }

                Section("Additional Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                    }
                    .disabled(name.isEmpty || description.isEmpty)
                }
            }
        }
    }

    private func saveRecipe() {
        let newRecipe = Recipe(
            id: recipe?.id ?? UUID(),
            name: name,
            description: description,
            gemstoneType: gemstoneType,
            parameters: parameters,
            expectedYield: expectedYieldLower...expectedYieldUpper,
            expectedQuality: expectedQualityLower...expectedQualityUpper,
            difficulty: difficulty,
            notes: notes
        )
        onSave(newRecipe)
        dismiss()
    }
}

#Preview {
    RecipesView()
        .environment(StoreManager())
}
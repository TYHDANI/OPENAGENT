import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddMaterial = false
    @State private var searchQuery = ""

    let collection: MaterialCollection

    var filteredMaterials: [Material] {
        if searchQuery.isEmpty {
            return collection.materials
        } else {
            return collection.materials.filter { material in
                material.name.localizedCaseInsensitiveContains(searchQuery) ||
                material.category.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Collection info card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: collection.iconName)
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Color(collection.colorName).gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            if let description = collection.descriptionText {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 16) {
                                Label("\(collection.materials.count) materials", systemImage: "cube.fill")
                                    .font(.caption)

                                Label("Created \(formatDate(collection.createdDate))", systemImage: "calendar")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }

                    // Add material button
                    Button {
                        showingAddMaterial = true
                    } label: {
                        Label("Add Material", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Search bar
                if !collection.materials.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Search in collection", text: $searchQuery)
                            .textFieldStyle(.plain)

                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Materials list
                if filteredMaterials.isEmpty && !searchQuery.isEmpty {
                    ContentUnavailableView {
                        Label("No Results", systemImage: "magnifyingglass")
                    } description: {
                        Text("No materials match '\(searchQuery)'")
                    }
                    .padding(.vertical, 40)
                } else if collection.materials.isEmpty {
                    ContentUnavailableView {
                        Label("Empty Collection", systemImage: "folder")
                    } description: {
                        Text("Add materials to organize them here")
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredMaterials) { material in
                            NavigationLink(destination: MaterialDetailView(material: material)) {
                                CollectionMaterialRow(
                                    material: material,
                                    onRemove: {
                                        removeMaterial(material)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddMaterial) {
            AddToCollectionView(collection: collection)
        }
    }

    private func removeMaterial(_ material: Material) {
        collection.removeMaterial(material)
        do {
            try modelContext.save()
        } catch {
            print("Failed to remove material: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CollectionMaterialRow: View {
    let material: Material
    let onRemove: () -> Void

    @State private var showingRemoveAlert = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCategory(material.category))
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(material.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !material.specifications.isEmpty {
                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(material.specifications.first?.fullSpec ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            Button {
                showingRemoveAlert = true
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Remove from Collection?", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemove()
            }
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Titanium Alloys": return "cube.fill"
        case "Nickel Alloys": return "cylinder.fill"
        case "Stainless Steels": return "shield.fill"
        case "Aluminum Alloys": return "square.stack.3d.up.fill"
        case "Composites": return "square.grid.3x3.fill"
        case "Ceramics": return "hexagon.fill"
        case "Semiconductors": return "cpu.fill"
        default: return "cube.transparent.fill"
        }
    }
}

struct AddToCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchQuery = ""
    @State private var selectedMaterials: Set<Material> = []
    @State private var materials: [Material] = []

    let collection: MaterialCollection

    var filteredMaterials: [Material] {
        let existingMaterialIDs = Set(collection.materials.map(\.id))
        let availableMaterials = materials.filter { !existingMaterialIDs.contains($0.id) }

        if searchQuery.isEmpty {
            return availableMaterials
        } else {
            return availableMaterials.filter { material in
                material.name.localizedCaseInsensitiveContains(searchQuery) ||
                material.category.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search materials", text: $searchQuery)
                        .textFieldStyle(.plain)

                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                Divider()

                // Materials list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredMaterials) { material in
                            MaterialSelectionRow(
                                material: material,
                                isSelected: selectedMaterials.contains(material),
                                onToggle: {
                                    if selectedMaterials.contains(material) {
                                        selectedMaterials.remove(material)
                                    } else {
                                        selectedMaterials.insert(material)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Materials")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedMaterials.count))") {
                        addSelectedMaterials()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedMaterials.isEmpty)
                }
            }
        }
        .onAppear {
            loadMaterials()
        }
    }

    private func loadMaterials() {
        do {
            var descriptor = FetchDescriptor<Material>()
            descriptor.sortBy = [SortDescriptor(\.name)]
            materials = try modelContext.fetch(descriptor)
        } catch {
            materials = []
        }
    }

    private func addSelectedMaterials() {
        for material in selectedMaterials {
            collection.addMaterial(material)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to add materials: \(error)")
        }
    }
}

struct MaterialSelectionRow: View {
    let material: Material
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(material.name)
                        .font(.subheadline)
                        .foregroundStyle(.primary)

                    Text(material.category)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected ? Color.accentColor.opacity(0.1) : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(
            collection: MaterialCollection(
                name: "Aerospace Materials",
                descriptionText: "High-performance materials for aircraft"
            )
        )
        .modelContainer(for: [Material.self, MaterialCollection.self])
    }
}
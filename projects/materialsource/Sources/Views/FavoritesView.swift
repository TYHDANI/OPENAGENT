import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FavoritesViewModel?
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    VStack(spacing: 0) {
                        // Tab picker
                        Picker("", selection: $selectedTab) {
                            Text("Favorites").tag(0)
                            Text("Collections").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        if selectedTab == 0 {
                            favoritesContent(viewModel)
                        } else {
                            collectionsContent(viewModel)
                        }
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            setupViewModel()
                        }
                }
            }
            .navigationTitle("Saved Materials")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedTab == 1 {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel?.showingNewCollection = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func favoritesContent(_ viewModel: FavoritesViewModel) -> some View {
        if viewModel.isLoading {
            Spacer()
            ProgressView("Loading favorites...")
            Spacer()
        } else if viewModel.favorites.isEmpty {
            ContentUnavailableView {
                Label("No Favorites", systemImage: "heart")
            } description: {
                Text("Materials you mark as favorite will appear here")
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.favorites) { material in
                        NavigationLink(destination: MaterialDetailView(material: material)) {
                            FavoriteMaterialCard(
                                material: material,
                                onRemove: {
                                    Task {
                                        await viewModel.removeFavorite(material)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func collectionsContent(_ viewModel: FavoritesViewModel) -> some View {
        if viewModel.collections.isEmpty {
            ContentUnavailableView {
                Label("No Collections", systemImage: "folder")
            } description: {
                Text("Create collections to organize your materials")
            } actions: {
                Button("Create Collection") {
                    viewModel.showingNewCollection = true
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.collections) { collection in
                        NavigationLink(destination: CollectionDetailView(collection: collection)) {
                            CollectionCard(
                                collection: collection,
                                onDelete: {
                                    Task {
                                        await viewModel.deleteCollection(collection)
                                    }
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }

        .sheet(isPresented: Binding(
            get: { viewModel.showingNewCollection },
            set: { viewModel.showingNewCollection = $0 }
        )) {
            NewCollectionSheet(viewModel: viewModel)
        }
    }

    private func setupViewModel() {
        let materialService = MaterialService(modelContext: modelContext)
        viewModel = FavoritesViewModel(
            modelContext: modelContext,
            materialService: materialService
        )

        Task {
            await viewModel?.loadFavorites()
            await viewModel?.loadCollections()
        }
    }
}

struct FavoriteMaterialCard: View {
    let material: Material
    let onRemove: () -> Void

    @State private var showingRemoveAlert = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCategory(material.category))
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.red.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(material.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(material.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !material.specifications.isEmpty {
                    Text(material.specifications.map(\.fullSpec).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                showingRemoveAlert = true
            } label: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .alert("Remove from Favorites?", isPresented: $showingRemoveAlert) {
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

struct CollectionCard: View {
    let collection: MaterialCollection
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: collection.iconName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color(collection.colorName).gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let description = collection.descriptionText {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    Label("\(collection.materials.count) materials", systemImage: "cube.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Updated \(formatDate(collection.modifiedDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Menu {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Collection", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .alert("Delete Collection?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This will permanently delete the collection. Materials will not be deleted.")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NewCollectionSheet: View {
    let viewModel: FavoritesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Collection Name") {
                    TextField("Enter name", text: $viewModel.newCollectionName)
                }

                Section("Description (Optional)") {
                    TextField("Enter description", text: $viewModel.newCollectionDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Appearance") {
                    // Icon picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(viewModel.availableIcons, id: \.self) { icon in
                                Button {
                                    viewModel.selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 60, height: 60)
                                        .background(viewModel.selectedIcon == icon ? Color.accentColor : Color(.systemGray5))
                                        .foregroundStyle(viewModel.selectedIcon == icon ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Color picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(viewModel.availableColors, id: \.self) { color in
                                Button {
                                    viewModel.selectedColor = color
                                } label: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(color))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            viewModel.selectedColor == color ?
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .font(.headline)
                                            : nil
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            let success = await viewModel.createCollection()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.newCollectionName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    FavoritesView()
        .environment(StoreManager())
        .modelContainer(for: [Material.self, Supplier.self, FavoriteMaterial.self, MaterialCollection.self])
}
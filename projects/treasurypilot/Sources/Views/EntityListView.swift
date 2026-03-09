import SwiftUI

struct EntityListView: View {
    @Environment(EntityViewModel.self) private var entityVM
    @Environment(StoreManager.self) private var storeManager
    @State private var showAddEntity = false

    var body: some View {
        NavigationStack {
            Group {
                if entityVM.entities.isEmpty {
                    ContentUnavailableView(
                        "No Entities",
                        systemImage: "building.2",
                        description: Text("Add your first legal entity to get started.")
                    )
                } else {
                    List {
                        ForEach(entityVM.entities) { entity in
                            NavigationLink(value: entity) {
                                EntityRowView(
                                    entity: entity,
                                    accountCount: entityVM.accounts(for: entity.id).count
                                )
                            }
                        }
                        .onDelete { offsets in
                            Task {
                                for index in offsets {
                                    await entityVM.deleteEntity(entityVM.entities[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Entities")
            .navigationDestination(for: LegalEntity.self) { entity in
                EntityDetailView(entity: entity)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddEntity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add entity")
                }
            }
            .sheet(isPresented: $showAddEntity) {
                AddEntitySheet()
            }
        }
    }
}

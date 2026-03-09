import SwiftUI

struct UserManagementView: View {
    @Environment(EntityViewModel.self) private var entityVM
    @State private var userVM = UserViewModel()
    @State private var showInvite = false

    var body: some View {
        NavigationStack {
            List {
                Section("Current User") {
                    if let user = userVM.currentUser {
                        HStack {
                            Image(systemName: user.role.icon)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .fontWeight(.medium)
                                Text(user.role.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Team Members (\(userVM.users.count))") {
                    ForEach(userVM.users) { user in
                        HStack {
                            Image(systemName: user.role.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.body)
                                if !user.email.isEmpty {
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(user.role.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(Capsule())
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await userVM.removeUser(userVM.users[index])
                            }
                        }
                    }

                    Button {
                        showInvite = true
                    } label: {
                        Label("Invite User", systemImage: "person.badge.plus")
                    }
                }

                Section("Audit Log") {
                    if userVM.auditLog.isEmpty {
                        Text("No audit entries")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(userVM.auditLog.suffix(20).reversed()) { entry in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.action.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(entry.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(entry.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Users & Access")
            .sheet(isPresented: $showInvite) {
                InviteUserSheet(entities: entityVM.entities, userVM: userVM)
            }
            .task {
                await userVM.load()
            }
        }
    }
}

struct InviteUserSheet: View {
    let entities: [LegalEntity]
    let userVM: UserViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var role: AccessRole = .readOnly
    @State private var selectedEntities: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("User Details") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Picker("Role", selection: $role) {
                        ForEach(AccessRole.allCases) { r in
                            Label(r.rawValue, systemImage: r.icon).tag(r)
                        }
                    }
                }

                Section("Entity Access") {
                    ForEach(entities) { entity in
                        Toggle(entity.name, isOn: Binding(
                            get: { selectedEntities.contains(entity.id) },
                            set: { isOn in
                                if isOn { selectedEntities.insert(entity.id) }
                                else { selectedEntities.remove(entity.id) }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Invite User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        Task {
                            await userVM.inviteUser(
                                name: name,
                                email: email,
                                role: role,
                                entityAccess: Array(selectedEntities)
                            )
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
}

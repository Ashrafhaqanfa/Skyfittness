//
//  ManageStaffView.swift
//  GymApp
//
//  Owner-only screen for admin access management ("Admin access" from notes).
//

import SwiftUI

struct ManageStaffView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var adminService = AdminService()
    @State private var showingAdd = false

    var body: some View {
        Group {
            if authService.currentAdmin?.role != .owner {
                VStack(spacing: 12) {
    Image(systemName: "PUT_THE_EXISTING_ICON_NAME_HERE")
        .font(.system(size: 48))
        .foregroundColor(.secondary)
    Text("PUT_THE_EXISTING_TITLE_HERE")
        .font(.headline)
    Text("PUT_THE_EXISTING_DESCRIPTION_HERE")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
            } else {
                List {
                    ForEach(adminService.admins) { admin in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(admin.name).font(.headline)
                            HStack {
                                Text(admin.loginEmail).font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Text(admin.role.rawValue.capitalized)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill") }
                    }
                }
                .sheet(isPresented: $showingAdd) {
                    AddStaffView(adminService: adminService)
                }
            }
        }
        .navigationTitle("Manage Staff")
        .onAppear { adminService.startListening() }
        .onDisappear { adminService.stopListening() }
    }
}

private struct AddStaffView: View {
    @ObservedObject var adminService: AdminService
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var role: Admin.AdminRole = .staff
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Temporary password", text: $password)
                Picker("Role", selection: $role) {
                    Text("Staff").tag(Admin.AdminRole.staff)
                    Text("Trainer").tag(Admin.AdminRole.trainer)
                }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.caption)
                }
            }
            .navigationTitle("Add Staff")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task {
                            isSaving = true
                            do {
                                try await adminService.addStaff(name: name, email: email, password: password, role: role)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.isEmpty || email.isEmpty || password.count < 6 || isSaving)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ManageStaffView() }.environmentObject(AuthService())
}

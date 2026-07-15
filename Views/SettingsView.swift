//
//  SettingsView.swift
//  GymApp
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var categoryPlanService = CategoryPlanService()

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let admin = authService.currentAdmin {
                        LabeledContent("Name", value: admin.name)
                        LabeledContent("Role", value: admin.role.rawValue.capitalized)
                        LabeledContent("Email", value: admin.loginEmail)
                    }
                    Button("Sign Out", role: .destructive) {
                        authService.signOut()
                    }
                }

                Section("Operations") {
                    NavigationLink(destination: AttendanceView()) {
                        Label("Attendance", systemImage: "checkmark.circle")
                    }
                    NavigationLink(destination: DietPlansView()) {
                        Label("Diet Plans", systemImage: "fork.knife")
                    }
                    NavigationLink(destination: ReferralsView()) {
                        Label("Refer & Earn", systemImage: "gift")
                    }
                    NavigationLink(destination: ReportsView()) {
                        Label("Reports (Balance Sheet PDF)", systemImage: "doc.richtext")
                    }
                }

                if authService.currentAdmin?.role == .owner {
                    Section("Admin") {
                        NavigationLink(destination: ManageStaffView()) {
                            Label("Manage Staff & Access", systemImage: "person.badge.key")
                        }
                    }
                }

                Section("Setup") {
                    Button("Load sample categories & plans") {
                        Task { await categoryPlanService.seedSampleDataIfNeeded() }
                    }
                    .disabled(!categoryPlanService.categories.isEmpty)
                    Text("Use this once on a fresh Firebase project to populate example categories (Exercise, Yoga, Weight Loss) and plans, so the Add Member form isn't empty.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Automated reminders") {
                    Label("WhatsApp/SMS expiry reminders run daily via Cloud Functions", systemImage: "message.badge")
                    Label("Birthday messages run daily via Cloud Functions", systemImage: "gift.fill")
                    Text("See /functions in the project — these need to be deployed once to Firebase for automated member-facing messages to work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("More")
            .onAppear { categoryPlanService.startListening() }
            .onDisappear { categoryPlanService.stopListening() }
        }
    }
}

#Preview {
    SettingsView().environmentObject(AuthService())
}

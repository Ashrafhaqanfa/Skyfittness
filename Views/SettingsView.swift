//
//  SettingsView.swift
//  GymApp
//
//  Redesigned as a "More"/profile sidebar matching the GoGym4U reference:
//  profile header, then grouped sections (Manage & List, Quick Actions,
//  Operations, Engagement, Reports & Settings, More).
//
//  Rows that map to a real, existing screen in this project (Attendance,
//  Diet Plans, Refer & Earn, Reports, Manage Staff, Enquiry) link there.
//  Rows that don't have a backing feature yet (AI Assistant, Subscription,
//  SMS, Exercise/Measurement libraries, QR check-in, Contact us,
//  Communication) link to a clearly-labeled ComingSoonView instead of
//  pretending to work.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var categoryPlanService = CategoryPlanService()

    var body: some View {
        NavigationStack {
            List {
                profileHeader

                Section("Quick Actions") {
                    NavigationLink(destination: ComingSoonView(title: "AI Assistant", icon: "sparkles")) {
                        row(icon: "sparkles", title: "AI Assistant", subtitle: "Your personal AI tool", badge: "New")
                    }
                    NavigationLink(destination: ComingSoonView(title: "Subscription", icon: "doc.text.fill")) {
                        row(icon: "doc.text.fill", title: "Subscription", subtitle: "Subscription Plans & Payments")
                    }
                }

                Section("Operations") {
                    NavigationLink(destination: AttendanceView()) {
                        row(icon: "checkmark.circle.fill", title: "Attendance", subtitle: "Track member attendance")
                    }
                    NavigationLink(destination: EnquiriesView()) {
                        row(icon: "tray.full.fill", title: "Enquiry", subtitle: "Track customer enquiries")
                    }
                    NavigationLink(destination: ComingSoonView(title: "Manage Expense", icon: "creditcard.fill")) {
                        row(icon: "creditcard.fill", title: "Manage Expense", subtitle: "Track business expenses")
                    }
                    NavigationLink(destination: ComingSoonView(title: "SMS", icon: "message.fill")) {
                        row(icon: "message.fill", title: "SMS", subtitle: "Send quick messages")
                    }
                }

                if authService.currentAdmin?.role == .owner {
                    Section("Admin") {
                        NavigationLink(destination: ManageStaffView()) {
                            row(icon: "person.badge.key.fill", title: "Manage Trainer/Staff", subtitle: "Add, edit users")
                        }
                    }
                }

                Section("Engagement") {
                    NavigationLink(destination: DietPlansView()) {
                        row(icon: "fork.knife.circle.fill", title: "Diet Adv.", subtitle: "Advanced diet plans")
                    }
                    NavigationLink(destination: ComingSoonView(title: "Exercise Adv.", icon: "figure.run.circle.fill")) {
                        row(icon: "figure.run.circle.fill", title: "Exercise Adv.", subtitle: "Workouts from exercises library")
                    }
                    NavigationLink(destination: ComingSoonView(title: "Measurement Adv.", icon: "ruler.fill")) {
                        row(icon: "ruler.fill", title: "Measurement Adv.", subtitle: "Track body metrics")
                    }
                }

                Section("Reports & Settings") {
                    NavigationLink(destination: ReportsView()) {
                        row(icon: "chart.bar.doc.horizontal.fill", title: "Report", subtitle: "View performance reports")
                    }
                    NavigationLink(destination: ComingSoonView(title: "Generate QR Code", icon: "qrcode")) {
                        row(icon: "qrcode", title: "Generate QR Code", subtitle: "Quick access check-in")
                    }
                }

                Section("More") {
                    NavigationLink(destination: ComingSoonView(title: "Need Help?", icon: "questionmark.circle.fill")) {
                        row(icon: "questionmark.circle.fill", title: "Need Help?", subtitle: "FAQs and Videos")
                    }
                    NavigationLink(destination: ReferralsView()) {
                        row(icon: "link.circle.fill", title: "Refer & Earn", subtitle: "Refer Friends • Earn Coins")
                    }
                    NavigationLink(destination: ComingSoonView(title: "Communication", icon: "bubble.left.and.bubble.right.fill")) {
                        row(icon: "bubble.left.and.bubble.right.fill", title: "Communication", subtitle: "Connect us")
                    }
                    NavigationLink(destination: ComingSoonView(title: "Contact us", icon: "phone.circle.fill")) {
                        row(icon: "phone.circle.fill", title: "Contact us", subtitle: "Report your query/issue")
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

                Section {
                    Button("Logout", role: .destructive) {
                        authService.signOut()
                    }
                }
            }
            .navigationTitle("More")
            .onAppear { categoryPlanService.startListening() }
            .onDisappear { categoryPlanService.stopListening() }
        }
    }

    private var profileHeader: some View {
        Section {
            if let admin = authService.currentAdmin {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(admin.name.first.map(String.init) ?? "?")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(admin.name) (\(admin.role.rawValue))")
                            .font(.headline)
                        Text("\(admin.loginEmail) (\(admin.role == .owner ? "Super Admin" : admin.role.rawValue.capitalized))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func row(icon: String, title: String, subtitle: String, badge: String? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title).font(.subheadline.weight(.semibold))
                    if let badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView().environmentObject(AuthService())
}

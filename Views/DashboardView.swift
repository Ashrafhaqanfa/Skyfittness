//
//  DashboardView.swift
//  GymApp
//
//  Redesigned to match the "GoGym4U" reference dashboard: photo banner,
//  Dashboard/Insights toggle, full stat-tile grid, a dashboard-theme picker,
//  and quick-access toolbar icons for Add Member / SMS / WhatsApp.
//
//  NOTE ON SCOPE: the SMS and WhatsApp "counters" in the reference app come
//  from a paid messaging-gateway subscription. There's no such gateway wired
//  up in this project, so those two sheets here are honest placeholders
//  (they show 0 credits and explain that no gateway is connected yet) rather
//  than fake numbers. Same for "Total Expense" — there's no ExpenseService
//  in the codebase yet, so it shows 0 until one is built.
//

import SwiftUI

private enum DashboardTheme: String, CaseIterable, Identifiable {
    case classic, sectionWise, animated, flow
    var id: String { rawValue }

    var title: String {
        switch self {
        case .classic: return "Classic"
        case .sectionWise: return "Section wise"
        case .animated: return "Animated"
        case .flow: return "Flow"
        }
    }
    var subtitle: String {
        switch self {
        case .classic: return "Simple grid layout with standard tiles."
        case .sectionWise: return "Group tiles by Members, Reports and more sections."
        case .animated: return "Add subtle animations and interactions to tiles."
        case .flow: return "A calm dashboard surface with grouped business metrics."
        }
    }
    var icon: String {
        switch self {
        case .classic: return "square.grid.2x2.fill"
        case .sectionWise: return "rectangle.grid.1x2.fill"
        case .animated: return "a.circle.fill"
        case .flow: return "square.grid.2x2"
        }
    }
}

private enum DashboardTab { case dashboard, insights }

struct DashboardView: View {
    @StateObject private var memberService = MemberService()
    @StateObject private var paymentService = PaymentService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var enquiryService = EnquiryService()
    @StateObject private var attendanceService = AttendanceService()

    @State private var tab: DashboardTab = .dashboard
    @State private var theme: DashboardTheme = .classic
    @State private var showThemePicker = false
    @State private var pendingTheme: DashboardTheme = .classic
    @State private var showAddMember = false
    @State private var showSMSCounter = false
    @State private var showWhatsAppCounter = false
    @State private var bannerIndex = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomLeading) {
                ScrollView {
                    VStack(spacing: 16) {
                        bannerCarousel

                        tabToggle
                            .padding(.horizontal)

                        if tab == .dashboard {
                            tilesContent
                        } else {
                            insightsPlaceholder
                        }
                    }
                    .padding(.bottom, 32)
                }

                themeFAB
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Heygym")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddMember = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSMSCounter = true } label: {
                        Image(systemName: "message.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showWhatsAppCounter = true } label: {
                        Image(systemName: "phone.bubble.left.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddMember) {
                AddEditMemberView(service: memberService)
            }
            .sheet(isPresented: $showSMSCounter) {
                MessageCounterSheet(title: "SMS Counter", tint: .blue)
            }
            .sheet(isPresented: $showWhatsAppCounter) {
                MessageCounterSheet(title: "WhatsApp Counter", tint: .green)
            }
            .sheet(isPresented: $showThemePicker) {
                themePickerSheet
            }
            .onAppear {
                memberService.startListening()
                paymentService.startListening()
                enquiryService.startListening()
                attendanceService.startListeningToday()
                Task { await notificationService.requestPermission() }
            }
            .onChange(of: memberService.members) { newMembers in
                notificationService.scheduleReminders(for: newMembers)
            }
            .onDisappear {
                memberService.stopListening()
                paymentService.stopListening()
                enquiryService.stopListening()
                attendanceService.stopListening()
            }
        }
    }

    // MARK: - Banner

    private var bannerCarousel: some View {
        TabView(selection: $bannerIndex) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.13, blue: 0.16), Color(red: 0.3, green: 0.33, blue: 0.38)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: ["dumbbell.fill", "figure.run", "figure.strengthtraining.traditional"][index])
                        .font(.system(size: 70))
                        .foregroundStyle(.white.opacity(0.18))
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Dashboard / Insights toggle

    private var tabToggle: some View {
        HStack(spacing: 8) {
            tabButton(title: "Dashboard", icon: "square.grid.2x2.fill", isSelected: tab == .dashboard) { tab = .dashboard }
            tabButton(title: "Insights", icon: "chart.line.uptrend.xyaxis", isSelected: tab == .insights) { tab = .insights }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }

    private func tabButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        }
        .background(isSelected ? Color(.systemBackground) : .clear)
        .clipShape(Capsule())
    }

    // MARK: - Tiles

    private var allTiles: [DashboardTile] {
        [
            DashboardTile(title: "Live Memberships", value: memberService.liveMembers.count, icon: "person.fill.checkmark", color: .green, group: .members),
            DashboardTile(title: "Total Memberships", value: memberService.totalMembersCount, icon: "person.3.fill", color: .blue, group: .members),
            DashboardTile(title: "Expired Memberships", value: memberService.expiredMembers.count, icon: "person.fill.xmark", color: .red, group: .members),
            DashboardTile(title: "Expiring (1-3 Days)", value: memberService.members(in: .expiring1to3).count, icon: "exclamationmark.triangle.fill", color: .orange, group: .members),
            DashboardTile(title: "Expiring (4-7 Days)", value: memberService.members(in: .expiring4to7).count, icon: "exclamationmark.triangle.fill", color: .orange, group: .members),
            DashboardTile(title: "Expiring (8-15 Days)", value: memberService.members(in: .expiring8to15).count, icon: "exclamationmark.triangle.fill", color: .yellow, group: .members),
            DashboardTile(title: "Demo Memberships", value: memberService.demoMembers.count, icon: "person.crop.circle.badge.questionmark", color: .purple, group: .members),
            DashboardTile(title: "Due Amount", value: nil, currency: memberService.totalDueAmount, icon: "briefcase.fill", color: .brown, group: .financial),
            DashboardTile(title: "Today Collection", value: nil, currency: paymentService.todaysCollection, icon: "indianrupeesign.circle.fill", color: .green, group: .financial),
            DashboardTile(title: "Total Collection", value: nil, currency: paymentService.totalCollection(), icon: "banknote.fill", color: .mint, group: .financial),
            DashboardTile(title: "Total Expense", value: nil, currency: 0, icon: "creditcard.fill", color: .pink, group: .financial),
            DashboardTile(title: "Balance Sheet", value: nil, icon: "chart.pie.fill", color: .indigo, group: .financial, destination: AnyView(ReportsView())),
            DashboardTile(title: "Due Amount Reminder", value: dueReminderCount, icon: "bell.badge.fill", color: .orange, group: .financial),
            DashboardTile(title: "Birthday", value: memberService.todaysBirthdays.count, icon: "birthday.cake.fill", color: .pink, group: .engagement),
            DashboardTile(title: "Anniversary", value: memberService.todaysAnniversaries.count, icon: "heart.fill", color: .red, group: .engagement),
            DashboardTile(title: "Today Follow-ups", value: enquiryService.todaysFollowUps.count, icon: "calendar.badge.clock", color: .blue, group: .engagement, destination: AnyView(EnquiriesView())),
            DashboardTile(title: "Enquiries", value: enquiryService.enquiries.count, icon: "person.2.wave.2.fill", color: .teal, group: .engagement, destination: AnyView(EnquiriesView())),
            DashboardTile(title: "Today Attendance", value: attendanceService.todaysAttendance.count, icon: "calendar.badge.checkmark", color: .cyan, group: .engagement, destination: AnyView(AttendanceView())),
        ]
    }

    private var dueReminderCount: Int {
        memberService.members.filter {
            guard let date = $0.dueAmountReminderDate else { return false }
            return Calendar.current.isDateInToday(date)
        }.count
    }

    @ViewBuilder
    private var tilesContent: some View {
        switch theme {
        case .classic, .animated:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(allTiles.enumerated()), id: \.element.title) { index, tile in
                    TileView(tile: tile, animated: theme == .animated, delayIndex: index)
                }
            }
            .padding(.horizontal)
        case .sectionWise:
            VStack(alignment: .leading, spacing: 20) {
                tileSection(title: "Members", tiles: allTiles.filter { $0.group == .members })
                tileSection(title: "Financial", tiles: allTiles.filter { $0.group == .financial })
                tileSection(title: "Engagement", tiles: allTiles.filter { $0.group == .engagement })
            }
        case .flow:
            VStack(spacing: 14) {
                ForEach(allTiles, id: \.title) { tile in
                    FlowRow(tile: tile)
                        .padding(.horizontal)
                }
            }
        }
    }

    private func tileSection(title: String, tiles: [DashboardTile]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(tiles, id: \.title) { tile in
                    TileView(tile: tile, animated: false, delayIndex: 0)
                }
            }
            .padding(.horizontal)
        }
    }

    private var insightsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Insights coming soon")
                .font(.headline)
            Text("Trend charts for collections, attendance, and churn will live here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }

    // MARK: - Theme picker FAB + sheet

    private var themeFAB: some View {
        Button {
            pendingTheme = theme
            showThemePicker = true
        } label: {
            Image(systemName: "paintpalette.fill")
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }

    private var themePickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Dashboard Theme")
                    .font(.title3.bold())
                Text("Select how you want your dashboard tiles to be displayed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 10) {
                    ForEach(DashboardTheme.allCases) { option in
                        Button {
                            pendingTheme = option
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: pendingTheme == option ? "largecircle.fill.circle" : "circle")
                                    .foregroundStyle(pendingTheme == option ? Color.accentColor : .secondary)
                                Image(systemName: option.icon)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 22)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                    Text(option.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(pendingTheme == option ? Color.accentColor.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(pendingTheme == option ? Color.accentColor : .clear, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                HStack {
                    Button("Cancel") { showThemePicker = false }
                    Spacer()
                    Button("Apply") {
                        theme = pendingTheme
                        showThemePicker = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Tile model + views

private enum TileGroup { case members, financial, engagement }

private struct DashboardTile {
    let title: String
    var value: Int? = nil
    var currency: Double? = nil
    let icon: String
    let color: Color
    let group: TileGroup
    var destination: AnyView? = nil

    var displayValue: String {
        if let currency { return "₹\(String(format: "%.0f", currency))" }
        return "\(value ?? 0)"
    }
}

private struct TileView: View {
    let tile: DashboardTile
    let animated: Bool
    let delayIndex: Int
    @State private var appeared = false

    var body: some View {
        Group {
            if let destination = tile.destination {
                NavigationLink(destination: destination) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
        .onAppear {
            guard animated else { appeared = true; return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(delayIndex) * 0.03)) {
                appeared = true
            }
        }
        .scaleEffect(animated && !appeared ? 0.85 : 1)
        .opacity(animated && !appeared ? 0 : 1)
    }

    private var content: some View {
        VStack(spacing: 8) {
            Image(systemName: tile.icon)
                .font(.title3)
                .foregroundStyle(tile.color)
                .frame(width: 40, height: 40)
                .background(tile.color.opacity(0.15))
                .clipShape(Circle())
            Text(tile.displayValue)
                .font(.title3.bold())
            Text(tile.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct FlowRow: View {
    let tile: DashboardTile

    var body: some View {
        Group {
            if let destination = tile.destination {
                NavigationLink(destination: destination) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack(spacing: 14) {
            Image(systemName: tile.icon)
                .font(.title3)
                .foregroundStyle(tile.color)
                .frame(width: 44, height: 44)
                .background(tile.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(tile.title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Text(tile.displayValue)
                .font(.headline)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Message counter placeholder sheet (SMS / WhatsApp)

private struct MessageCounterSheet: View {
    let title: String
    let tint: Color
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(title)
                    .font(.title2.bold())
                    .padding(.top, 12)

                counterRow(label: "Credit Messages", value: 0, tint: .blue)
                counterRow(label: "Left Messages", value: 0, tint: .green)
                counterRow(label: "Used Messages", value: 0, tint: .red)

                Text("No messaging gateway is connected yet, so this always shows 0. Hook up an SMS/WhatsApp provider (e.g. Twilio, Gupshup, or Meta's WhatsApp Business API) via a Cloud Function to make this real.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No Message History")
                        .font(.headline)
                    Text("Message History not found.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func counterRow(label: String, value: Int, tint: Color) -> some View {
        HStack {
            Text(label).font(.subheadline.weight(.semibold))
            Spacer()
            Text("\(value)").font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(tint.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
}

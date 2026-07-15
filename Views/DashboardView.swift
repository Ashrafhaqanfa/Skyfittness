//
//  DashboardView.swift
//  GymApp
//
//  At-a-glance home screen: today's collection, due amount, expiring members,
//  birthdays/anniversaries, matching the right-hand column of the original notes.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var memberService = MemberService()
    @StateObject private var paymentService = PaymentService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var enquiryService = EnquiryService()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(title: "Live Members", value: "\(memberService.liveMembers.count)", icon: "person.fill.checkmark", color: .green)
                    StatCard(title: "Total Members", value: "\(memberService.totalMembersCount)", icon: "person.3.fill", color: .blue)
                    StatCard(title: "Expired", value: "\(memberService.expiredMembers.count)", icon: "person.fill.xmark", color: .red)
                    StatCard(title: "Expiring (1-3d)", value: "\(memberService.members(in: .expiring1to3).count)", icon: "exclamationmark.triangle.fill", color: .orange)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    if !memberService.todaysBirthdays.isEmpty {
                        InfoRow(icon: "gift.fill", color: .pink, text: "\(memberService.todaysBirthdays.count) birthday(s) today")
                    }
                    if !memberService.todaysAnniversaries.isEmpty {
                        InfoRow(icon: "star.fill", color: .purple, text: "\(memberService.todaysAnniversaries.count) membership anniversary(ies) today")
                    }
                    InfoRow(icon: "indianrupeesign.circle.fill", color: .green, text: "Today's collection: ₹\(paymentService.todaysCollection, specifier: "%.0f")")
                    NavigationLink(destination: EnquiriesView()) {
                        InfoRow(icon: "clock.fill", color: .blue, text: "Follow-ups due today: \(enquiryService.todaysFollowUps.count)")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                memberService.startListening()
                paymentService.startListening()
                enquiryService.startListening()
                Task { await notificationService.requestPermission() }
            }
            .onChange(of: memberService.members) { _, newMembers in
                notificationService.scheduleReminders(for: newMembers)
            }
            .onDisappear {
                memberService.stopListening()
                paymentService.stopListening()
                enquiryService.stopListening()
            }
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct InfoRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

#Preview {
    DashboardView()
}

//
//  MembersListView.swift
//  GymApp
//
//  Members list with Live / Expired / Expiring (1-3, 4-7, 8-15 day) filters,
//  matching the "Admin access" section of the original notes.
//

import SwiftUI

struct MembersListView: View {
    @StateObject private var service = MemberService()
    @State private var selectedFilter: MemberFilter = .live
    @State private var showingAddMember = false

    enum MemberFilter: String, CaseIterable, Identifiable {
        case live = "Live"
        case total = "Total"
        case expired = "Expired"
        case expiring1to3 = "1-3 Days"
        case expiring4to7 = "4-7 Days"
        case expiring8to15 = "8-15 Days"
        case demo = "Demo"

        var id: String { rawValue }
    }

    private var filteredMembers: [Member] {
        switch selectedFilter {
        case .live: return service.liveMembers
        case .total: return service.members
        case .expired: return service.expiredMembers
        case .expiring1to3: return service.members(in: .expiring1to3)
        case .expiring4to7: return service.members(in: .expiring4to7)
        case .expiring8to15: return service.members(in: .expiring8to15)
        case .demo: return service.members.filter { $0.status == .demo }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MemberFilter.allCases) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if service.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredMembers.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
    Image(systemName: "PUT_EXISTING_ICON_NAME_HERE")
        .font(.system(size: 48))
        .foregroundColor(.secondary)
    Text("PUT_EXISTING_TITLE_HERE")
        .font(.headline)
    Text("PUT_EXISTING_DESCRIPTION_HERE")
        .font(.subheadline)
        .foregroundColor(.secondary)
}
                    Spacer()
                } else {
                    List(filteredMembers) { member in
                        NavigationLink(destination: MemberDetailView(member: member, service: service)) {
                            MemberRow(member: member)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Members")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMember = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddEditMemberView(service: service)
            }
            .onAppear { service.startListening() }
            .onDisappear { service.stopListening() }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct MemberRow: View {
    let member: Member

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.headline)
                Text(member.phone)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge
                if member.dueAmount > 0 {
                    Text("Due: ₹\(member.dueAmount, specifier: "%.0f")")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(member.isExpired ? "Expired" : "\(member.daysUntilExpiry)d left")
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        if member.isExpired { return .red }
        if member.daysUntilExpiry <= 3 { return .orange }
        if member.daysUntilExpiry <= 15 { return .yellow }
        return .green
    }
}

#Preview {
    MembersListView()
}

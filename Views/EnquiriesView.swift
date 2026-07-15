//
//  EnquiriesView.swift
//  GymApp
//

import SwiftUI

struct EnquiriesView: View {
    @StateObject private var service = EnquiryService()
    @State private var selectedStatus: Enquiry.EnquiryStatus?
    @State private var showingAdd = false

    private var filtered: [Enquiry] {
        guard let selectedStatus else { return service.enquiries }
        return service.enquiries(with: selectedStatus)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        StatusChip(title: "All", isSelected: selectedStatus == nil) { selectedStatus = nil }
                        ForEach(Enquiry.EnquiryStatus.allCases, id: \.self) { status in
                            StatusChip(title: status.rawValue.capitalized, isSelected: selectedStatus == status) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                if !service.todaysFollowUps.isEmpty && selectedStatus == nil {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark.fill").foregroundStyle(.orange)
                        Text("\(service.todaysFollowUps.count) follow-up(s) due today")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                }

                if filtered.isEmpty {
                    Spacer()
                    ContentUnavailableView("No enquiries", systemImage: "person.badge.plus", description: Text("Tap + to add a new lead."))
                    Spacer()
                } else {
                    List(filtered) { enquiry in
                        NavigationLink(destination: AddEditEnquiryView(service: service, existingEnquiry: enquiry)) {
                            EnquiryRow(enquiry: enquiry)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Enquiries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditEnquiryView(service: service)
            }
            .onAppear { service.startListening() }
            .onDisappear { service.stopListening() }
        }
    }
}

private struct StatusChip: View {
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

private struct EnquiryRow: View {
    let enquiry: Enquiry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(enquiry.name).font(.headline)
                Text(enquiry.phone).font(.caption).foregroundStyle(.secondary)
                if let category = enquiry.interestCategory {
                    Text(category).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(enquiry.status.rawValue.capitalized)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
                if let date = enquiry.followUpDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusColor: Color {
        switch enquiry.status {
        case .new: return .blue
        case .contacted: return .orange
        case .converted: return .green
        case .lost: return .red
        }
    }
}

#Preview {
    EnquiriesView()
}

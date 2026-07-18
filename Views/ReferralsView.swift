//
//  ReferralsView.swift
//  GymApp
//

import SwiftUI

struct ReferralsView: View {
    @StateObject private var referralService = ReferralService()
    @StateObject private var memberService = MemberService()
    @State private var showingAdd = false

    var body: some View {
        List {
            if referralService.referrals.isEmpty {
                ContentUnavailableView("No referrals yet", systemImage: "gift", description: Text("Tap + to log a member's referral."))
            } else {
                ForEach(referralService.referrals) { referral in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(referral.referredName).font(.headline)
                            Spacer()
                            statusBadge(referral.rewardStatus)
                        }
                        Text("Referred by: \(referrerName(referral.referrerMemberId))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(referral.referredPhone)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if referral.rewardStatus != .rewardGiven {
                            Menu("Update status") {
                                ForEach(Referral.RewardStatus.allCases, id: \.self) { status in
                                    Button(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized) {
                                        referralService.updateStatus(referral, to: status)
                                    }
                                }
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Refer & Earn")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddReferralView(referralService: referralService, memberService: memberService)
        }
        .onAppear {
            referralService.startListening()
            memberService.startListening()
        }
        .onDisappear {
            referralService.stopListening()
            memberService.stopListening()
        }
    }

    private func referrerName(_ id: String) -> String {
        memberService.members.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    private func statusBadge(_ status: Referral.RewardStatus) -> some View {
        let color: Color = status == .rewarded ? .green : status == .converted ? .orange : .blue
        return Text(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

private struct AddReferralView: View {
    @ObservedObject var referralService: ReferralService
    @ObservedObject var memberService: MemberService
    @Environment(\.dismiss) private var dismiss

    @State private var referrerId = ""
    @State private var referredName = ""
    @State private var referredPhone = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Referred by (existing member)", selection: $referrerId) {
                    Text("Select member").tag("")
                    ForEach(memberService.members) { member in
                        Text(member.name).tag(member.id ?? "")
                    }
                }
                TextField("New person's name", text: $referredName)
                TextField("New person's phone", text: $referredPhone).keyboardType(.phonePad)
            }
            .navigationTitle("Log Referral")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task {
                            isSaving = true
                            try? await referralService.addReferral(referrerMemberId: referrerId, referredName: referredName, referredPhone: referredPhone)
                            dismiss()
                        }
                    }
                    .disabled(referrerId.isEmpty || referredName.isEmpty || isSaving)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { ReferralsView() }
}

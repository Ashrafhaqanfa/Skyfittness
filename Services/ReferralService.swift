//
//  ReferralService.swift
//  GymApp
//
//  "Refer & Earn" tracking from the notes.
//

import Foundation
import FirebaseFirestore


@MainActor
final class ReferralService: ObservableObject {
    @Published var referrals: [Referral] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        listener = db.collection("referrals")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.referrals = snapshot?.documents.compactMap { try? $0.data(as: Referral.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addReferral(referrerMemberId: String, referredName: String, referredPhone: String) async throws {
        let referral = Referral(referrerMemberId: referrerMemberId, referredName: referredName, referredPhone: referredPhone)
        _ = try db.collection("referrals").addDocument(from: referral)
    }

    func updateStatus(_ referral: Referral, to status: Referral.RewardStatus) {
        guard let id = referral.id else { return }
        db.collection("referrals").document(id).updateData(["rewardStatus": status.rawValue])
    }

    func referrals(by memberId: String) -> [Referral] {
        referrals.filter { $0.referrerMemberId == memberId }
    }
}

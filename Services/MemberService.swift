//
//  MemberService.swift
//  GymApp
//
//  Handles all Firestore reads/writes for Members.
//  Requires: Firebase SDK added via Swift Package Manager
//  (https://github.com/firebase/firebase-ios-sdk), FirebaseFirestore + FirebaseFirestoreSwift.
//

import Foundation
import FirebaseFirestore

@MainActor
final class MemberService: ObservableObject {
    @Published var members: [Member] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    /// Starts a live listener on the members collection.
    func startListening() {
        isLoading = true
        listener = db.collection("members")
            .order(by: "expiryDate")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.members = snapshot?.documents.compactMap {
                    try? $0.data(as: Member.self)
                } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addMember(_ member: Member) async throws {
        _ = try db.collection("members").addDocument(from: member)
    }

    func updateMember(_ member: Member) throws {
        guard let id = member.id else { return }
        try db.collection("members").document(id).setData(from: member, merge: true)
    }

    func deleteMember(_ member: Member) {
        guard let id = member.id else { return }
        db.collection("members").document(id).delete()
    }

    // MARK: - Filters matching your notes (Live / Total / Expired / Expiring buckets)

    var liveMembers: [Member] { members.filter { $0.status == .live && !$0.isExpired } }
    var totalMembersCount: Int { members.count }
    var expiredMembers: [Member] { members.filter { $0.isExpired } }
    var demoMembers: [Member] { members.filter { $0.status == .demo } }
    var totalDueAmount: Double { members.reduce(0) { $0 + $1.dueAmount } }

    func members(in bucket: Member.ExpiryBucket) -> [Member] {
        members.filter { $0.expiryBucket == bucket }
    }

    var todaysBirthdays: [Member] { members.filter { $0.isBirthdayToday } }
    var todaysAnniversaries: [Member] { members.filter { $0.isAnniversaryToday } }
}

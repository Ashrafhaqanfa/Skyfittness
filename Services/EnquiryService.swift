//
//  EnquiryService.swift
//  GymApp
//
//  Lead/enquiry tracking with follow-up scheduling and conversion status.
//

import Foundation
import FirebaseFirestore

@MainActor
final class EnquiryService: ObservableObject {
    @Published var enquiries: [Enquiry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("enquiries")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.enquiries = snapshot?.documents.compactMap { try? $0.data(as: Enquiry.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addEnquiry(_ enquiry: Enquiry) async throws {
        _ = try db.collection("enquiries").addDocument(from: enquiry)
    }

    func updateEnquiry(_ enquiry: Enquiry) throws {
        guard let id = enquiry.id else { return }
        try db.collection("enquiries").document(id).setData(from: enquiry, merge: true)
    }

    func deleteEnquiry(_ enquiry: Enquiry) {
        guard let id = enquiry.id else { return }
        db.collection("enquiries").document(id).delete()
    }

    // MARK: - Filters (matches "Today follow-ups / Enquiries" from notes)

    var todaysFollowUps: [Enquiry] {
        enquiries.filter {
            guard let date = $0.followUpDate else { return false }
            return Calendar.current.isDateInToday(date) && $0.status != .converted && $0.status != .lost
        }
    }

    func enquiries(with status: Enquiry.EnquiryStatus) -> [Enquiry] {
        enquiries.filter { $0.status == status }
    }
}

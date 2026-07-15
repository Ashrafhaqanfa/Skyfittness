//
//  PaymentService.swift
//  GymApp
//
//  Records payments, updates member due amounts, and calculates
//  Today's Collection / Total Collection (with monthly filter) from your notes.
//

import Foundation
import FirebaseFirestore

@MainActor
final class PaymentService: ObservableObject {
    @Published var payments: [Payment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("payments")
            .order(by: "paymentDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.payments = snapshot?.documents.compactMap { try? $0.data(as: Payment.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Records a payment AND reduces the member's due amount in a single atomic write.
    func recordPayment(memberId: String, amount: Double, mode: Payment.PaymentMode, collectedBy: String?, currentDueAmount: Double) async throws {
        let batch = db.batch()

        let paymentRef = db.collection("payments").document()
        let payment = Payment(memberId: memberId, amount: amount, mode: mode, collectedBy: collectedBy)
        try batch.setData(from: payment, forDocument: paymentRef)

        let memberRef = db.collection("members").document(memberId)
        let newDue = max(0, currentDueAmount - amount)
        batch.updateData(["dueAmount": newDue, "updatedAt": Date()], forDocument: memberRef)

        try await batch.commit()
    }

    // MARK: - Collection calculations (matches "Today's Collection / Total Collection -> Monthly filter")

    var todaysCollection: Double {
        let cal = Calendar.current
        return payments
            .filter { cal.isDateInToday($0.paymentDate) }
            .reduce(0) { $0 + $1.amount }
    }

    func totalCollection(month: Int? = nil, year: Int? = nil) -> Double {
        guard let month, let year else {
            return payments.reduce(0) { $0 + $1.amount }
        }
        let cal = Calendar.current
        return payments
            .filter {
                cal.component(.month, from: $0.paymentDate) == month &&
                cal.component(.year, from: $0.paymentDate) == year
            }
            .reduce(0) { $0 + $1.amount }
    }

    func payments(for memberId: String) -> [Payment] {
        payments.filter { $0.memberId == memberId }
    }
}

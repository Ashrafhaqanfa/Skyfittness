//
//  DietPlanService.swift
//  GymApp
//

import Foundation
import FirebaseFirestore



@MainActor
final class DietPlanService: ObservableObject {
    @Published var dietPlans: [DietPlan] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        listener = db.collection("dietPlans")
            .order(by: "assignedDate", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.dietPlans = snapshot?.documents.compactMap { try? $0.data(as: DietPlan.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addDietPlan(_ plan: DietPlan) async throws {
        _ = try db.collection("dietPlans").addDocument(from: plan)
    }

    func deleteDietPlan(_ plan: DietPlan) {
        guard let id = plan.id else { return }
        db.collection("dietPlans").document(id).delete()
    }

    func plans(for memberId: String) -> [DietPlan] {
        dietPlans.filter { $0.memberId == memberId }
    }
}

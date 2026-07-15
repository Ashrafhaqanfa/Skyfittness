//
//  CategoryPlanService.swift
//  GymApp
//
//  Manages Category and Plan collections (the "Category -> Plan -> Assign" hierarchy).
//  Also seeds sample data on first launch if the collections are empty, so the app
//  isn't empty on a fresh Firebase project.
//

import Foundation
import FirebaseFirestore

@MainActor
final class CategoryPlanService: ObservableObject {
    @Published var categories: [Category] = []
    @Published var plans: [Plan] = []

    private let db = Firestore.firestore()
    private var categoryListener: ListenerRegistration?
    private var planListener: ListenerRegistration?

    func startListening() {
        categoryListener = db.collection("categories")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.categories = snapshot?.documents.compactMap { try? $0.data(as: Category.self) } ?? []
            }

        planListener = db.collection("plans")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.plans = snapshot?.documents.compactMap { try? $0.data(as: Plan.self) } ?? []
            }
    }

    func stopListening() {
        categoryListener?.remove()
        planListener?.remove()
    }

    func plans(for categoryId: String) -> [Plan] {
        plans.filter { $0.categoryId == categoryId }
    }

    func addCategory(name: String) async throws {
        _ = try db.collection("categories").addDocument(from: Category(name: name))
    }

    func addPlan(categoryId: String, name: String, durationDays: Int, price: Double) async throws {
        let plan = Plan(categoryId: categoryId, name: name, durationDays: durationDays, price: price)
        _ = try db.collection("plans").addDocument(from: plan)
    }

    /// Run once from a debug button or on first launch to populate example data.
    func seedSampleDataIfNeeded() async {
        guard categories.isEmpty else { return }
        do {
            let exerciseId = try db.collection("categories").addDocument(from: Category(name: "Exercise")).documentID
            let weightLossId = try db.collection("categories").addDocument(from: Category(name: "Weight Loss")).documentID
            let yogaId = try db.collection("categories").addDocument(from: Category(name: "Yoga")).documentID

            try db.collection("plans").addDocument(from: Plan(categoryId: exerciseId, name: "1-Month Standard", durationDays: 30, price: 1500))
            try db.collection("plans").addDocument(from: Plan(categoryId: exerciseId, name: "3-Month Gold", durationDays: 90, price: 4000))
            try db.collection("plans").addDocument(from: Plan(categoryId: exerciseId, name: "12-Month Elite", durationDays: 365, price: 14000))
            try db.collection("plans").addDocument(from: Plan(categoryId: weightLossId, name: "6-Month Program", durationDays: 180, price: 8000))
            try db.collection("plans").addDocument(from: Plan(categoryId: yogaId, name: "1-Month Yoga", durationDays: 30, price: 1200))
        } catch {
            print("Seed error: \(error)")
        }
    }
}

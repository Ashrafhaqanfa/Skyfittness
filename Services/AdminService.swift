//
//  AdminService.swift
//  GymApp
//
//  Lists staff/admins, and creates new staff accounts via the
//  `createStaffAccount` Cloud Function (server-side, so it doesn't
//  sign the calling owner out — see /functions/index.js).
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
final class AdminService: ObservableObject {
    @Published var admins: [Admin] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private lazy var functions = Functions.functions()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("admins").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            self.isLoading = false
            if let error {
                self.errorMessage = error.localizedDescription
                return
            }
            self.admins = snapshot?.documents.compactMap { try? $0.data(as: Admin.self) } ?? []
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func addStaff(name: String, email: String, password: String, role: Admin.AdminRole) async throws {
        let callable = functions.httpsCallable("createStaffAccount")
        _ = try await callable.call([
            "name": name,
            "email": email,
            "password": password,
            "role": role.rawValue,
        ])
    }
}

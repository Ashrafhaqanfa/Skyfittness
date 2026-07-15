//
//  AuthService.swift
//  GymApp
//
//  Handles admin login/logout via Firebase Auth (email/password).
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var currentAdmin: Admin?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var authHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user {
                    await self?.loadAdminProfile(uid: user.uid)
                } else {
                    self?.currentAdmin = nil
                }
            }
        }
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    var isLoggedIn: Bool { currentUser != nil }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Use once to create the first owner account. Afterwards, create staff/trainer
    /// accounts from an in-app "Manage Staff" screen instead of exposing signup publicly.
    func signUp(name: String, email: String, password: String, role: Admin.AdminRole = .owner) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let admin = Admin(id: result.user.uid, name: name, role: role, loginEmail: email)
            try db.collection("admins").document(result.user.uid).setData(from: admin)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    private func loadAdminProfile(uid: String) async {
        do {
            let doc = try await db.collection("admins").document(uid).getDocument()
            currentAdmin = try doc.data(as: Admin.self)
        } catch {
            // Profile doc might not exist yet right after signup; not a fatal error.
            currentAdmin = nil
        }
    }
}

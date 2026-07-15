//
//  GymApp.swift
//  GymApp
//
//  App entry point. Requires Firebase configured via GoogleService-Info.plist
//  (see SETUP.md for step-by-step instructions).
//

import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct GymApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authService = AuthService()

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoggedIn {
                    RootTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(authService)
        }
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

            MembersListView()
                .tabItem { Label("Members", systemImage: "person.3.fill") }

            PaymentsView()
                .tabItem { Label("Payments", systemImage: "indianrupeesign.circle.fill") }

            EnquiriesView()
                .tabItem { Label("Enquiries", systemImage: "person.badge.plus") }

            SettingsView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
    }
}

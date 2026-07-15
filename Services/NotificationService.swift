//
//  NotificationService.swift
//  GymApp
//
//  Schedules LOCAL notifications on the admin's device for birthdays, anniversaries,
//  and expiring memberships. This covers reminders to the gym owner/admin.
//
//  IMPORTANT LIMITATION: local notifications only fire reliably if scheduled while
//  the app has run recently (iOS caps how far ahead + how many can be pending).
//  For reminders sent TO MEMBERS (WhatsApp/SMS), see the Cloud Functions in
//  /functions — those run server-side on a daily schedule regardless of whether
//  the app is open, which is what you actually want for member-facing reminders.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published var permissionGranted = false

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            permissionGranted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            permissionGranted = false
        }
    }

    /// Call this once after members load (e.g. from Dashboard.onAppear) to (re)schedule
    /// admin-facing reminders. Clears old scheduled notifications first to avoid duplicates.
    func scheduleReminders(for members: [Member]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for member in members {
            scheduleExpiryReminder(member: member, center: center)
            scheduleBirthdayReminder(member: member, center: center)
        }
    }

    private func scheduleExpiryReminder(member: Member, center: UNUserNotificationCenter) {
        // Remind the admin 3 days before expiry, at 9 AM.
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -3, to: member.expiryDate),
              reminderDate > Date() else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9

        let content = UNMutableNotificationContent()
        content.title = "Membership expiring soon"
        content.body = "\(member.name)'s plan expires in 3 days. Consider sending a renewal reminder."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "expiry-\(member.id ?? UUID().uuidString)", content: content, trigger: trigger)
        center.add(request)
    }

    private func scheduleBirthdayReminder(member: Member, center: UNUserNotificationCenter) {
        guard let dob = member.dateOfBirth else { return }
        var components = Calendar.current.dateComponents([.month, .day], from: dob)
        components.hour = 9 // Fires every year on this date (repeats: true, no year component)

        let content = UNMutableNotificationContent()
        content.title = "🎂 Birthday today"
        content.body = "It's \(member.name)'s birthday today — send them a wish!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "birthday-\(member.id ?? UUID().uuidString)", content: content, trigger: trigger)
        center.add(request)
    }
}

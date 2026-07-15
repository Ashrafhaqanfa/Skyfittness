//
//  ReminderService.swift
//  GymApp
//
//  Calls the `sendManualReminder` Cloud Function (see /functions/index.js)
//  so a staff member can trigger an immediate WhatsApp/SMS reminder from
//  the Member Detail screen, on top of the automated daily reminders.
//
//  This MUST go through a Cloud Function rather than calling Twilio directly
//  from the app — Twilio credentials can never be embedded client-side.
//

import Foundation
import FirebaseFunctions

@MainActor
final class ReminderService: ObservableObject {
    enum Channel: String {
        case whatsapp
        case sms
    }

    @Published var isSending: Channel?
    @Published var lastResultMessage: String?
    @Published var lastResultWasError = false

    private lazy var functions = Functions.functions()

    func send(memberId: String, channel: Channel) async {
        guard !memberId.isEmpty else {
            lastResultMessage = "Can't send reminder — member not saved yet."
            lastResultWasError = true
            return
        }

        isSending = channel
        lastResultMessage = nil

        do {
            let callable = functions.httpsCallable("sendManualReminder")
            _ = try await callable.call([
                "memberId": memberId,
                "channel": channel.rawValue,
            ])
            lastResultMessage = "\(channel == .whatsapp ? "WhatsApp" : "SMS") reminder sent."
            lastResultWasError = false
        } catch {
            lastResultMessage = "Failed to send: \(error.localizedDescription)"
            lastResultWasError = true
        }

        isSending = nil
    }
}

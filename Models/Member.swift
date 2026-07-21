//
//  Member.swift
//  GymApp
//
//  Core member model + status logic (Live / Expired / Expiring buckets)
//

import Foundation
import FirebaseFirestore

enum MemberStatus: String, Codable, Equatable {
    case live
    case expired
    case demo
}

struct Member: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var phone: String
    var email: String?
    var dateOfBirth: Date?
    var joinDate: Date
    var categoryId: String
    var planId: String
    var status: MemberStatus
    var expiryDate: Date
    var dueAmount: Double
    var adminId: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Extra profile fields (added to match the "Add Member" reference design)
    // All optional/defaulted so older Firestore documents without these keys still decode fine.
    var memberCode: String?              // human-friendly "Member ID" shown at the top of the form
    var address: String?
    var gender: Gender?
    var dialCode: String = "+91"
    var goal: String?
    var heightCm: Double?
    var weightKg: Double?
    var isVIP: Bool = false
    var batch: String?
    var marriageAnniversary: Date?
    var homePhone: String?
    var careOf: String?
    var uniqueIdNumber: String?
    var companyName: String?
    var companyGST: String?
    var remark: String?
    var enrollmentFee: Double = 0
    var discountType: String?
    var discountAmount: Double = 0
    var taxAmount: Double = 0
    var paidAmount: Double = 0
    var dueAmountReminderDate: Date?

    enum Gender: String, Codable, CaseIterable {
        case male, female
    }

    // MARK: - Derived status logic (matches your notes: 1-3 / 4-7 / 8-15 day buckets)

    /// Days remaining until expiry. Negative if already expired.
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }

    var isExpired: Bool {
        daysUntilExpiry < 0
    }

    enum ExpiryBucket: String, CaseIterable {
        case expiring1to3 = "Expiring in 1-3 days"
        case expiring4to7 = "Expiring in 4-7 days"
        case expiring8to15 = "Expiring in 8-15 days"
        case notExpiringSoon = "Not expiring soon"
        case expired = "Expired"
    }

    var expiryBucket: ExpiryBucket {
        if isExpired { return .expired }
        switch daysUntilExpiry {
        case 0...3: return .expiring1to3
        case 4...7: return .expiring4to7
        case 8...15: return .expiring8to15
        default: return .notExpiringSoon
        }
    }

    var isBirthdayToday: Bool {
        guard let dob = dateOfBirth else { return false }
        let cal = Calendar.current
        return cal.component(.month, from: dob) == cal.component(.month, from: Date())
            && cal.component(.day, from: dob) == cal.component(.day, from: Date())
    }

    var isAnniversaryToday: Bool {
        let cal = Calendar.current
        return cal.component(.month, from: joinDate) == cal.component(.month, from: Date())
            && cal.component(.day, from: joinDate) == cal.component(.day, from: Date())
    }
}

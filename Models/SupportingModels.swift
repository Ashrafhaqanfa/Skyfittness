//
//  SupportingModels.swift
//  GymApp
//
//  Category, Plan, Payment, Admin, Attendance, Enquiry
//

import Foundation
import FirebaseFirestore

struct Category: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String   // e.g. "Exercise", "Weight Loss", "Yoga"
}

struct Plan: Identifiable, Codable {
    @DocumentID var id: String?
    var categoryId: String
    var name: String        // e.g. "3-Month Gold"
    var durationDays: Int
    var price: Double
}

struct Payment: Identifiable, Codable {
    @DocumentID var id: String?
    var memberId: String
    var amount: Double
    var paymentDate: Date = Date()
    var mode: PaymentMode
    var collectedBy: String?

    enum PaymentMode: String, Codable, CaseIterable {
        case cash, upi, card, other
    }
}

struct Admin: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var role: AdminRole
    var loginEmail: String

    enum AdminRole: String, Codable, CaseIterable {
        case owner, staff, trainer
    }
}

struct Attendance: Identifiable, Codable {
    @DocumentID var id: String?
    var memberId: String
    var date: Date = Date()
    var checkInTime: Date = Date()
}

struct Enquiry: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var phone: String
    var interestCategory: String?
    var followUpDate: Date?
    var status: EnquiryStatus = .new
    var notes: String?
    var createdAt: Date = Date()

    enum EnquiryStatus: String, Codable, CaseIterable {
        case new, contacted, converted, lost
    }
}

struct Referral: Identifiable, Codable {
    @DocumentID var id: String?
    var referrerMemberId: String
    var referredName: String
    var referredPhone: String
    var rewardStatus: RewardStatus = .pending
    var createdAt: Date = Date()

    enum RewardStatus: String, Codable, CaseIterable {
        case pending, converted, rewarded
    }
}

struct DietPlan: Identifiable, Codable {
    @DocumentID var id: String?
    var memberId: String
    var title: String
    var planDetails: String
    var assignedBy: String?
    var createdAt: Date = Date()
}

//
//  MemberDetailView.swift
//  GymApp
//

import SwiftUI

struct MemberDetailView: View {
    let member: Member
    @ObservedObject var service: MemberService
    @StateObject private var paymentService = PaymentService()
    @StateObject private var categoryPlanService = CategoryPlanService()
    @StateObject private var reminderService = ReminderService()
    @State private var showingEdit = false
    @State private var showingRecordPayment = false

    var body: some View {
        List {
            Section("Profile") {
                LabeledContent("Name", value: member.name)
                LabeledContent("Phone", value: member.phone)
                if let email = member.email {
                    LabeledContent("Email", value: email)
                }
            }

            Section("Membership") {
                LabeledContent("Category", value: categoryPlanService.categories.first(where: { $0.id == member.categoryId })?.name ?? "—")
                LabeledContent("Plan", value: categoryPlanService.plans.first(where: { $0.id == member.planId })?.name ?? "—")
                LabeledContent("Join date", value: member.joinDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Expiry date", value: member.expiryDate.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Status") {
                    Text(member.isExpired ? "Expired" : "\(member.daysUntilExpiry) days left")
                        .foregroundStyle(member.isExpired ? .red : .green)
                }
            }

            Section("Billing") {
                LabeledContent("Due amount", value: "₹\(member.dueAmount, specifier: "%.2f")")
                Button("Record Payment") {
                    showingRecordPayment = true
                }
                if !paymentService.payments(for: member.id ?? "").isEmpty {
                    DisclosureGroup("Payment history") {
                        ForEach(paymentService.payments(for: member.id ?? "")) { payment in
                            HStack {
                                Text(payment.paymentDate.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text("₹\(payment.amount, specifier: "%.0f")")
                            }
                            .font(.caption)
                        }
                    }
                }
            }

            Section {
                Button {
                    Task { await reminderService.send(memberId: member.id ?? "", channel: .whatsapp) }
                } label: {
                    HStack {
                        Text("Send 3-Day Payment Reminder (WhatsApp)")
                        if reminderService.isSending == .whatsapp {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(reminderService.isSending != nil || member.id == nil)

                Button {
                    Task { await reminderService.send(memberId: member.id ?? "", channel: .sms) }
                } label: {
                    HStack {
                        Text("Send SMS Reminder")
                        if reminderService.isSending == .sms {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(reminderService.isSending != nil || member.id == nil)

                if let confirmation = reminderService.lastResultMessage {
                    Text(confirmation)
                        .font(.caption)
                        .foregroundStyle(reminderService.lastResultWasError ? .red : .green)
                }
            }

            Section {
                Button("Delete Member", role: .destructive) {
                    service.deleteMember(member)
                }
            }
        }
        .navigationTitle(member.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditMemberView(service: service, existingMember: member)
        }
        .sheet(isPresented: $showingRecordPayment) {
            RecordPaymentView(member: member, paymentService: paymentService)
        }
        .onAppear {
            paymentService.startListening()
            categoryPlanService.startListening()
        }
        .onDisappear {
            paymentService.stopListening()
            categoryPlanService.stopListening()
        }
    }
}

//
//  RecordPaymentView.swift
//  GymApp
//

import SwiftUI

struct RecordPaymentView: View {
    let member: Member
    @ObservedObject var paymentService: PaymentService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String
    @State private var mode: Payment.PaymentMode = .cash
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(member: Member, paymentService: PaymentService) {
        self.member = member
        self.paymentService = paymentService
        _amountText = State(initialValue: member.dueAmount > 0 ? String(format: "%.0f", member.dueAmount) : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Member", value: member.name)
                    LabeledContent("Current due", value: "₹\(String(format: "%.2f", member.dueAmount))")
                }

                Section("Payment") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Mode", selection: $mode) {
                        Text("Cash").tag(Payment.PaymentMode.cash)
                        Text("UPI").tag(Payment.PaymentMode.upi)
                        Text("Card").tag(Payment.PaymentMode.card)
                        Text("Other").tag(Payment.PaymentMode.other)
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Record Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled((Double(amountText) ?? 0) <= 0 || isSaving)
                }
            }
        }
    }

    private func save() async {
        guard let memberId = member.id, let amount = Double(amountText), amount > 0 else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await paymentService.recordPayment(
                memberId: memberId,
                amount: amount,
                mode: mode,
                collectedBy: authService.currentAdmin?.id,
                currentDueAmount: member.dueAmount
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

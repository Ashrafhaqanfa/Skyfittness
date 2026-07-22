//
//  RecordPaymentView.swift
//  GymApp
//
//  After a payment is saved, a PDF receipt is generated automatically and
//  offered via the share sheet (save, print, WhatsApp/AirDrop it, etc.)
//  before the screen closes.
//

import SwiftUI

struct RecordPaymentView: View {
    let member: Member
    @ObservedObject var paymentService: PaymentService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @AppStorage("gymName") private var gymName = "My Gym"

    @State private var amountText: String
    @State private var mode: Payment.PaymentMode = .cash
    @State private var isSaving = false
    @State private var errorMessage: String?

    // Receipt state
    @State private var receiptURL: URL?
    @State private var showingReceiptSheet = false

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

                if receiptURL != nil {
                    Section {
                        Button {
                            showingReceiptSheet = true
                        } label: {
                            Label("Share / Save Receipt", systemImage: "square.and.arrow.up.fill")
                        }
                    } footer: {
                        Text("Payment saved. A PDF receipt was generated automatically — tap above to share, print, or save it.")
                    }
                }
            }
            .navigationTitle("Record Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(receiptURL == nil ? "Cancel" : "Done") { dismiss() }
                }
                if receiptURL == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                            .disabled((Double(amountText) ?? 0) <= 0 || isSaving)
                    }
                }
            }
            .sheet(isPresented: $showingReceiptSheet) {
                if let receiptURL {
                    ShareSheet(items: [receiptURL])
                }
            }
        }
    }

    private func save() async {
        guard let memberId = member.id, let amount = Double(amountText), amount > 0 else { return }
        isSaving = true
        errorMessage = nil
        do {
            let dueBefore = member.dueAmount
            let dueAfter = max(0, dueBefore - amount)

            let savedPayment = try await paymentService.recordPayment(
                memberId: memberId,
                amount: amount,
                mode: mode,
                collectedBy: authService.currentAdmin?.id,
                currentDueAmount: dueBefore
            )

            // Generate the receipt right away — every single payment gets one.
            receiptURL = ReceiptService.generateReceiptPDF(
                gymName: gymName,
                member: member,
                payment: savedPayment,
                dueBefore: dueBefore,
                dueAfter: dueAfter
            )

            // Immediately present the share sheet once, so it's not an extra tap
            // for the common case of wanting to send the receipt right away.
            if receiptURL != nil {
                showingReceiptSheet = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    RecordPaymentView(
        member: Member(name: "Test", phone: "9999999999", joinDate: Date(), categoryId: "", planId: "", status: .live, expiryDate: Date(), dueAmount: 500),
        paymentService: PaymentService()
    )
    .environmentObject(AuthService())
}

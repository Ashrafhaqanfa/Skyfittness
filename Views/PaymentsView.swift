//
//  PaymentsView.swift
//  GymApp
//
//  Today's Collection / Total Collection (monthly filter) + Balance Sheet list.
//

import SwiftUI

struct PaymentsView: View {
    @StateObject private var paymentService = PaymentService()
    @StateObject private var memberService = MemberService()
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    private let months = Calendar.current.monthSymbols

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's Collection").font(.caption).foregroundStyle(.secondary)
                            Text("₹\(paymentService.todaysCollection, specifier: "%.0f")")
                                .font(.title2.bold())
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Total Due (all members)").font(.caption).foregroundStyle(.secondary)
                            Text("₹\(totalDue, specifier: "%.0f")")
                                .font(.title2.bold())
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { i in
                            Text(months[i - 1]).tag(i)
                        }
                    }
                    HStack {
                        Text("Monthly Total")
                        Spacer()
                        Text("₹\(paymentService.totalCollection(month: selectedMonth, year: selectedYear), specifier: "%.0f")")
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Monthly Filter")
                }

                Section("Recent Payments (Balance Sheet)") {
                    if paymentService.payments.isEmpty {
                        Text("No payments recorded yet").foregroundStyle(.secondary)
                    } else {
                        ForEach(paymentService.payments.prefix(50)) { payment in
                            PaymentRow(payment: payment, memberName: memberName(for: payment.memberId))
                        }
                    }
                }
            }
            .navigationTitle("Payments")
            .onAppear {
                paymentService.startListening()
                memberService.startListening()
            }
            .onDisappear {
                paymentService.stopListening()
                memberService.stopListening()
            }
        }
    }

    private var totalDue: Double {
        memberService.members.reduce(0) { $0 + $1.dueAmount }
    }

    private func memberName(for id: String) -> String {
        memberService.members.first(where: { $0.id == id })?.name ?? "Unknown member"
    }
}

private struct PaymentRow: View {
    let payment: Payment
    let memberName: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(memberName).font(.subheadline.weight(.medium))
                Text(payment.paymentDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("₹\(payment.amount, specifier: "%.0f")")
                    .font(.subheadline.weight(.semibold))
                Text(payment.mode.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PaymentsView()
}

//
//  ReportsView.swift
//  GymApp
//

import SwiftUI

struct ReportsView: View {
    @StateObject private var memberService = MemberService()
    @StateObject private var paymentService = PaymentService()
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var gymName = "My Gym"
    @State private var generatedPDFURL: URL?
    @State private var showingShareSheet = false

    private let months = Calendar.current.monthSymbols

    var body: some View {
        Form {
            Section("Gym Details") {
                TextField("Gym name (shown on report)", text: $gymName)
            }

            Section("Report Period") {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { i in Text(months[i - 1]).tag(i) }
                }
                Stepper("Year: \(selectedYear)", value: $selectedYear, in: 2020...2035)
            }

            Section {
                Button("Generate Balance Sheet PDF") {
                    generatedPDFURL = ReportService.generateBalanceSheetPDF(
                        gymName: gymName,
                        members: memberService.members,
                        payments: paymentService.payments,
                        month: selectedMonth,
                        year: selectedYear
                    )
                    if generatedPDFURL != nil { showingShareSheet = true }
                }
            }

            if let url = generatedPDFURL {
                Section("Last Generated") {
                    Text(url.lastPathComponent).font(.caption).foregroundStyle(.secondary)
                    Button("Share / Save") { showingShareSheet = true }
                }
            }
        }
        .navigationTitle("Reports")
        .sheet(isPresented: $showingShareSheet) {
            if let url = generatedPDFURL {
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            memberService.startListening()
            paymentService.startListening()
        }
        .onDisappear {
            memberService.stopListening()
            paymentService.stopListening()
        }
    }
}

/// Wraps UIActivityViewController so SwiftUI can present the native iOS share sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack { ReportsView() }
}

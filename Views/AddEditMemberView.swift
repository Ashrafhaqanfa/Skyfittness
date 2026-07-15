//
//  AddEditMemberView.swift
//  GymApp
//
//  Form for adding/editing a member: Category -> Plan -> Assignment,
//  matching the "Diagnosis: Exercise -> Category / Plan / Assign" section of the notes.
//

import SwiftUI

struct AddEditMemberView: View {
    @ObservedObject var service: MemberService
    @Environment(\.dismiss) private var dismiss

    var existingMember: Member?

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var dateOfBirth = Date()
    @State private var joinDate = Date()
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var dueAmount = ""
    @State private var status: MemberStatus = .live

    @StateObject private var categoryPlanService = CategoryPlanService()
    @State private var selectedCategoryId = ""
    @State private var selectedPlanId = ""

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Full name", text: $name)
                    TextField("Phone number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                    DatePicker("Date of birth", selection: $dateOfBirth, displayedComponents: .date)
                }

                Section("Category / Plan / Assignment") {
                    if categoryPlanService.categories.isEmpty {
                        Text("No categories yet — add some from More \u{2192} Setup, or tap 'Load sample categories & plans'.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategoryId) {
                            ForEach(categoryPlanService.categories) { category in
                                Text(category.name).tag(category.id ?? "")
                            }
                        }
                        Picker("Plan", selection: $selectedPlanId) {
                            ForEach(categoryPlanService.plans(for: selectedCategoryId)) { plan in
                                Text("\(plan.name) — ₹\(plan.price, specifier: "%.0f")").tag(plan.id ?? "")
                            }
                        }
                    }
                }

                Section("Membership") {
                    DatePicker("Join date", selection: $joinDate, displayedComponents: .date)
                    DatePicker("Expiry date", selection: $expiryDate, displayedComponents: .date)
                    Picker("Status", selection: $status) {
                        Text("Live").tag(MemberStatus.live)
                        Text("Demo").tag(MemberStatus.demo)
                        Text("Expired").tag(MemberStatus.expired)
                    }
                }

                Section("Billing") {
                    TextField("Due amount", text: $dueAmount)
                        .keyboardType(.decimalPad)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(existingMember == nil ? "Add Member" : "Edit Member")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(name.isEmpty || phone.isEmpty || isSaving)
                }
            }
            .onAppear {
                categoryPlanService.startListening()
                loadExistingIfNeeded()
            }
            .onDisappear { categoryPlanService.stopListening() }
            .onChange(of: selectedPlanId) { _, newPlanId in
                // Auto-calculate expiry date from the plan's duration, from join date
                if let plan = categoryPlanService.plans.first(where: { $0.id == newPlanId }) {
                    expiryDate = Calendar.current.date(byAdding: .day, value: plan.durationDays, to: joinDate) ?? expiryDate
                    dueAmount = String(format: "%.0f", plan.price)
                }
            }
        }
    }

    private func loadExistingIfNeeded() {
        guard let m = existingMember else { return }
        name = m.name
        phone = m.phone
        email = m.email ?? ""
        dateOfBirth = m.dateOfBirth ?? Date()
        joinDate = m.joinDate
        expiryDate = m.expiryDate
        dueAmount = String(m.dueAmount)
        status = m.status
        selectedCategoryId = m.categoryId
        selectedPlanId = m.planId
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let member = Member(
            id: existingMember?.id,
            name: name,
            phone: phone,
            email: email.isEmpty ? nil : email,
            dateOfBirth: dateOfBirth,
            joinDate: joinDate,
            categoryId: selectedCategoryId,
            planId: selectedPlanId,
            status: status,
            expiryDate: expiryDate,
            dueAmount: Double(dueAmount) ?? 0
        )
        do {
            if existingMember != nil {
                try service.updateMember(member)
            } else {
                try await service.addMember(member)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    AddEditMemberView(service: MemberService())
}

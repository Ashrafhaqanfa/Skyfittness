//
//  AddEditEnquiryView.swift
//  GymApp
//

import SwiftUI

struct AddEditEnquiryView: View {
    @ObservedObject var service: EnquiryService
    @Environment(\.dismiss) private var dismiss

    var existingEnquiry: Enquiry?

    @State private var name = ""
    @State private var phone = ""
    @State private var interestCategory = ""
    @State private var followUpDate = Date()
    @State private var hasFollowUp = true
    @State private var status: Enquiry.EnquiryStatus = .new
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Lead Info") {
                TextField("Name", text: $name)
                TextField("Phone", text: $phone).keyboardType(.phonePad)
                TextField("Interested in (e.g. Yoga, Weight Loss)", text: $interestCategory)
            }

            Section("Follow-up") {
                Toggle("Schedule follow-up", isOn: $hasFollowUp)
                if hasFollowUp {
                    DatePicker("Follow-up date", selection: $followUpDate, displayedComponents: .date)
                }
                Picker("Status", selection: $status) {
                    ForEach(Enquiry.EnquiryStatus.allCases, id: \.self) { s in
                        Text(s.rawValue.capitalized).tag(s)
                    }
                }
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }

            if existingEnquiry != nil {
                Section {
                    Button("Delete Enquiry", role: .destructive) {
                        if let e = existingEnquiry { service.deleteEnquiry(e) }
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(existingEnquiry == nil ? "New Enquiry" : "Edit Enquiry")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                    .disabled(name.isEmpty || phone.isEmpty || isSaving)
            }
        }
        .onAppear(perform: loadExistingIfNeeded)
    }

    private func loadExistingIfNeeded() {
        guard let e = existingEnquiry else { return }
        name = e.name
        phone = e.phone
        interestCategory = e.interestCategory ?? ""
        if let date = e.followUpDate {
            followUpDate = date
            hasFollowUp = true
        } else {
            hasFollowUp = false
        }
        status = e.status
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let enquiry = Enquiry(
            id: existingEnquiry?.id,
            name: name,
            phone: phone,
            interestCategory: interestCategory.isEmpty ? nil : interestCategory,
            followUpDate: hasFollowUp ? followUpDate : nil,
            status: status
        )
        do {
            if existingEnquiry != nil {
                try service.updateEnquiry(enquiry)
            } else {
                try await service.addEnquiry(enquiry)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack { AddEditEnquiryView(service: EnquiryService()) }
}

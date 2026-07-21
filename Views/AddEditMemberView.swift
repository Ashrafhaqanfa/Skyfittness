//
//  AddEditMemberView.swift
//  GymApp
//
//  Redesigned to match the "GoGym4U" Add Member reference: avatar picker,
//  Member ID, Gender toggle, collapsible "Plan Details" and "Other Details"
//  sections, VIP toggle, and a document-upload row.
//
//  NOTE ON SCOPE: the avatar and the 3 "Doc" photo slots are wired up with
//  a real PhotosUI picker and preview, but the images are only kept
//  in-memory for now — they are NOT uploaded anywhere. Actually persisting
//  them needs the FirebaseStorage package added to the project (it isn't
//  currently a dependency here), plus upload code in MemberService. That's
//  a good next step once you're ready for it.
//

import SwiftUI
import PhotosUI
import UIKit

struct AddEditMemberView: View {
    @ObservedObject var service: MemberService
    @Environment(\.dismiss) private var dismiss

    var existingMember: Member?

    // Basic info
    @State private var memberCode = ""
    @State private var name = ""
    @State private var address = ""
    @State private var gender: Member.Gender = .male
    @State private var dialCode = "+91"
    @State private var phone = ""
    @State private var dateOfBirth: Date?
    @State private var goal = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var isVIP = false

    // Plan details
    @State private var joinDate = Date()
    @State private var expiryDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var dueAmount = ""
    @State private var status: MemberStatus = .live
    @StateObject private var categoryPlanService = CategoryPlanService()
    @State private var selectedCategoryId = ""
    @State private var selectedPlanId = ""
    @State private var planAmount = ""
    @State private var paymentMode: Payment.PaymentMode = .cash
    @State private var paidAmount = ""
    @State private var enrollmentFee = "0"
    @State private var discountType = "None"
    @State private var discount = ""
    @State private var taxAmount = "0"
    @State private var dueAmountReminderDate: Date?
    @State private var billDate = Date()

    // Other details
    @State private var batch = ""
    @State private var marriageAnniversary: Date?
    @State private var email = ""
    @State private var homePhone = ""
    @State private var careOf = ""
    @State private var uniqueIdNumber = ""
    @State private var companyName = ""
    @State private var companyGST = ""
    @State private var remark = ""

    // Photos (in-memory only — see note above)
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var docItems: [PhotosPickerItem?] = [nil, nil, nil]
    @State private var docImages: [Image?] = [nil, nil, nil]

    // UI state
    @State private var isPlanSectionExpanded = true
    @State private var isOtherSectionExpanded = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let discountTypes = ["None", "Flat", "Percentage"]
    private let batches = ["Morning", "Afternoon", "Evening", "General"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    avatarPicker

                    fieldGroup {
                        labeledField(label: "Member ID", trailing: "available") {
                            TextField("Member ID", text: $memberCode)
                                .keyboardType(.numberPad)
                        }
                        plainField("Name", text: $name)
                        plainField("Address", text: $address)

                        HStack {
                            Text("Gender").foregroundStyle(.secondary)
                            Spacer()
                            Picker("Gender", selection: $gender) {
                                Text("Male").tag(Member.Gender.male)
                                Text("Female").tag(Member.Gender.female)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }

                        HStack(spacing: 10) {
                            Menu(dialCode) {
                                ForEach(["+91", "+1", "+44", "+971"], id: \.self) { code in
                                    Button(code) { dialCode = code }
                                }
                            }
                            .frame(width: 70)
                            TextField("Mobile", text: $phone)
                                .keyboardType(.phonePad)
                        }

                        HStack(spacing: 10) {
                            datePickerField(label: "Date Of Birth", date: $dateOfBirth)
                            TextField("Goal", text: $goal)
                        }

                        HStack(spacing: 10) {
                            TextField("Height (cm)", text: $height).keyboardType(.decimalPad)
                            TextField("Weight (kg)", text: $weight).keyboardType(.decimalPad)
                        }

                        Toggle(isOn: $isVIP) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("VIP Member").font(.subheadline.weight(.semibold))
                                Text("Select this for VIP members. No plan is required.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    disclosureCard(title: "Plan Details", icon: "tv.fill", isExpanded: $isPlanSectionExpanded) {
                        if categoryPlanService.categories.isEmpty {
                            Text("No categories yet — add some from More → Setup, or tap 'Load sample categories & plans'.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Category", selection: $selectedCategoryId) {
                                ForEach(categoryPlanService.categories) { category in
                                    Text(category.name).tag(category.id ?? "")
                                }
                            }
                            Picker("Plan", selection: $selectedPlanId) {
                                Text("Plan").tag("")
                                ForEach(categoryPlanService.plans(for: selectedCategoryId)) { plan in
                                    Text("\(plan.name) — ₹\(String(format: "%.0f", plan.price))").tag(plan.id ?? "")
                                }
                            }
                        }
                        plainField("Plan Amount", text: $planAmount, keyboard: .decimalPad)
                        datePickerField(label: "Start Date", date: Binding(get: { joinDate }, set: { joinDate = $0 ?? Date() }))
                        datePickerField(label: "Expiry Date", date: Binding(get: { expiryDate }, set: { expiryDate = $0 ?? expiryDate }))

                        HStack {
                            Text("Payment Method").foregroundStyle(.secondary)
                            Spacer()
                            Picker("Payment Method", selection: $paymentMode) {
                                ForEach(Payment.PaymentMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue.uppercased()).tag(mode)
                                }
                            }
                        }
                        plainField("Paid Amount", text: $paidAmount, keyboard: .decimalPad)
                        plainField("Enrollment Fee", text: $enrollmentFee, keyboard: .decimalPad)

                        HStack {
                            Text("Discount Type").foregroundStyle(.secondary)
                            Spacer()
                            Picker("Discount Type", selection: $discountType) {
                                ForEach(discountTypes, id: \.self) { Text($0).tag($0) }
                            }
                        }
                        plainField("Discount", text: $discount, keyboard: .decimalPad)
                        plainField("Tax Amount", text: $taxAmount, keyboard: .decimalPad)
                        plainField("Due Amount", text: $dueAmount, keyboard: .decimalPad)
                        datePickerField(label: "Due Amount Reminder", date: $dueAmountReminderDate)
                        datePickerField(label: "Bill Date", date: Binding(get: { billDate }, set: { billDate = $0 ?? billDate }))
                    }

                    disclosureCard(title: "Other Details", icon: "info.circle.fill", isExpanded: $isOtherSectionExpanded) {
                        Text("Upload Documents").font(.subheadline.weight(.semibold))
                        HStack(spacing: 12) {
                            docSlot(index: 0, label: "Doc 1")
                            docSlot(index: 1, label: "Doc 2")
                            docSlot(index: 2, label: "Doc 3")
                        }

                        HStack {
                            Text("Batch").foregroundStyle(.secondary)
                            Spacer()
                            Picker("Batch", selection: $batch) {
                                Text("Batch").tag("")
                                ForEach(batches, id: \.self) { Text($0).tag($0) }
                            }
                        }
                        datePickerField(label: "Marriage Anniversary", date: $marriageAnniversary)
                        plainField("Email", text: $email, keyboard: .emailAddress)
                        plainField("Home Phone", text: $homePhone, keyboard: .phonePad)
                        plainField("Care Of (c/o)", text: $careOf)
                        plainField("Unique ID Number", text: $uniqueIdNumber)
                        plainField("Place of Work / Company Name", text: $companyName)
                        plainField("Company GST", text: $companyGST)
                        plainField("Remark", text: $remark)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(existingMember == nil ? "Add Member" : "Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(name.isEmpty || phone.isEmpty || isSaving)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if categoryPlanService.categories.isEmpty && !isVIP {
                    HStack {
                        Text("No Plans Found! Go to the More tab → Setup to load categories & plans.")
                            .font(.caption)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.85))
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                categoryPlanService.startListening()
                loadExistingIfNeeded()
            }
            .onDisappear { categoryPlanService.stopListening() }
            .onChange(of: selectedPlanId) { newPlanId in
                if let plan = categoryPlanService.plans.first(where: { $0.id == newPlanId }) {
                    expiryDate = Calendar.current.date(byAdding: .day, value: plan.durationDays, to: joinDate) ?? expiryDate
                    dueAmount = String(format: "%.0f", plan.price)
                    planAmount = String(format: "%.0f", plan.price)
                }
            }
        }
    }

    // MARK: - Reusable pieces

    private var avatarPicker: some View {
        VStack(spacing: 8) {
            Text("Select Image").font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let avatarImage {
                        avatarImage.resizable().scaledToFill()
                    } else {
                        Circle().fill(Color.green.opacity(0.25))
                            .overlay(Image(systemName: "person.fill").font(.system(size: 40)).foregroundStyle(.white))
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())

                PhotosPicker(selection: $avatarItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onChange(of: avatarItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                    avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }

    private func docSlot(index: Int, label: String) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image = docImages[index] {
                    image.resizable().scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottomLeading) {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(4)
            }

            PhotosPicker(selection: Binding(
                get: { docItems[index] },
                set: { newValue in
                    docItems[index] = newValue
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                            docImages[index] = Image(uiImage: uiImage)
                        }
                    }
                }
            ), matching: .images) {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }
        }
    }

    private func fieldGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) { content() }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func disclosureCard<Content: View>(title: String, icon: String, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { isExpanded.wrappedValue.toggle() }
            } label: {
                HStack {
                    Image(systemName: icon).foregroundStyle(Color.accentColor)
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                VStack(spacing: 12) { content() }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func plainField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func labeledField<Content: View>(label: String, trailing: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            content()
            Text(trailing).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func datePickerField(label: String, date: Binding<Date?>) -> some View {
        HStack {
            Text(label).foregroundStyle(date.wrappedValue == nil ? .secondary : .primary)
            Spacer()
            DatePicker("", selection: Binding(get: { date.wrappedValue ?? Date() }, set: { date.wrappedValue = $0 }), displayedComponents: .date)
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Load / Save

    private func loadExistingIfNeeded() {
        guard let m = existingMember else { return }
        memberCode = m.memberCode ?? ""
        name = m.name
        address = m.address ?? ""
        gender = m.gender ?? .male
        dialCode = m.dialCode
        phone = m.phone
        email = m.email ?? ""
        dateOfBirth = m.dateOfBirth
        goal = m.goal ?? ""
        height = m.heightCm.map { String($0) } ?? ""
        weight = m.weightKg.map { String($0) } ?? ""
        isVIP = m.isVIP
        joinDate = m.joinDate
        expiryDate = m.expiryDate
        dueAmount = String(m.dueAmount)
        status = m.status
        selectedCategoryId = m.categoryId
        selectedPlanId = m.planId
        enrollmentFee = String(m.enrollmentFee)
        discountType = m.discountType ?? "None"
        discount = String(m.discountAmount)
        taxAmount = String(m.taxAmount)
        paidAmount = String(m.paidAmount)
        dueAmountReminderDate = m.dueAmountReminderDate
        batch = m.batch ?? ""
        marriageAnniversary = m.marriageAnniversary
        homePhone = m.homePhone ?? ""
        careOf = m.careOf ?? ""
        uniqueIdNumber = m.uniqueIdNumber ?? ""
        companyName = m.companyName ?? ""
        companyGST = m.companyGST ?? ""
        remark = m.remark ?? ""
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
            dueAmount: Double(dueAmount) ?? 0,
            memberCode: memberCode.isEmpty ? nil : memberCode,
            address: address.isEmpty ? nil : address,
            gender: gender,
            dialCode: dialCode,
            goal: goal.isEmpty ? nil : goal,
            heightCm: Double(height),
            weightKg: Double(weight),
            isVIP: isVIP,
            batch: batch.isEmpty ? nil : batch,
            marriageAnniversary: marriageAnniversary,
            homePhone: homePhone.isEmpty ? nil : homePhone,
            careOf: careOf.isEmpty ? nil : careOf,
            uniqueIdNumber: uniqueIdNumber.isEmpty ? nil : uniqueIdNumber,
            companyName: companyName.isEmpty ? nil : companyName,
            companyGST: companyGST.isEmpty ? nil : companyGST,
            remark: remark.isEmpty ? nil : remark,
            enrollmentFee: Double(enrollmentFee) ?? 0,
            discountType: discountType == "None" ? nil : discountType,
            discountAmount: Double(discount) ?? 0,
            taxAmount: Double(taxAmount) ?? 0,
            paidAmount: Double(paidAmount) ?? 0,
            dueAmountReminderDate: dueAmountReminderDate
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

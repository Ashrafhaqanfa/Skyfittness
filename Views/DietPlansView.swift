//
//  DietPlansView.swift
//  GymApp
//

import SwiftUI

struct DietPlansView: View {
    @StateObject private var dietPlanService = DietPlanService()
    @StateObject private var memberService = MemberService()
    @State private var showingAdd = false

    var body: some View {
        List {
            if dietPlanService.dietPlans.isEmpty {
                ContentUnavailableView("No diet plans assigned", systemImage: "fork.knife", description: Text("Tap + to assign one."))
            } else {
                ForEach(dietPlanService.dietPlans) { plan in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title).font(.headline)
                        Text(memberName(plan.memberId)).font(.caption).foregroundStyle(.secondary)
                        Text(plan.planDetails).font(.caption2).lineLimit(2)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { dietPlanService.deleteDietPlan(plan) }
                    }
                }
            }
        }
        .navigationTitle("Diet Plans")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus.circle.fill") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddDietPlanView(dietPlanService: dietPlanService, memberService: memberService)
        }
        .onAppear {
            dietPlanService.startListening()
            memberService.startListening()
        }
        .onDisappear {
            dietPlanService.stopListening()
            memberService.stopListening()
        }
    }

    private func memberName(_ id: String) -> String {
        memberService.members.first(where: { $0.id == id })?.name ?? "Unknown"
    }
}

private struct AddDietPlanView: View {
    @ObservedObject var dietPlanService: DietPlanService
    @ObservedObject var memberService: MemberService
    @Environment(\.dismiss) private var dismiss

    @State private var memberId = ""
    @State private var title = ""
    @State private var details = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("Member", selection: $memberId) {
                    Text("Select member").tag("")
                    ForEach(memberService.members) { member in
                        Text(member.name).tag(member.id ?? "")
                    }
                }
                TextField("Plan title (e.g. High Protein Plan)", text: $title)
                TextField("Plan details", text: $details, axis: .vertical)
                    .lineLimit(5...10)
            }
            .navigationTitle("Assign Diet Plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task {
                            isSaving = true
                            let plan = DietPlan(memberId: memberId, title: title, planDetails: details)
                            try? await dietPlanService.addDietPlan(plan)
                            dismiss()
                        }
                    }
                    .disabled(memberId.isEmpty || title.isEmpty || isSaving)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { DietPlansView() }
}

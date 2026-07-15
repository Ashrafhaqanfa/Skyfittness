//
//  AttendanceView.swift
//  GymApp
//
//  Today's check-in list. Search a member and mark them present —
//  matches "Today Attendance" from the original notes.
//

import SwiftUI

struct AttendanceView: View {
    @StateObject private var attendanceService = AttendanceService()
    @StateObject private var memberService = MemberService()
    @State private var searchText = ""

    private var filteredMembers: [Member] {
        let live = memberService.liveMembers
        guard !searchText.isEmpty else { return live }
        return live.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.phone.contains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Checked in today")
                        Spacer()
                        Text("\(attendanceService.todaysAttendance.count) / \(memberService.liveMembers.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Mark Attendance") {
                    ForEach(filteredMembers) { member in
                        HStack {
                            Text(member.name)
                            Spacer()
                            let checkedIn = attendanceService.hasCheckedInToday(memberId: member.id ?? "")
                            Button {
                                Task {
                                    if checkedIn {
                                        attendanceService.undoCheckIn(memberId: member.id ?? "")
                                    } else {
                                        try? await attendanceService.checkIn(memberId: member.id ?? "")
                                    }
                                }
                            } label: {
                                Label(checkedIn ? "Checked In" : "Check In", systemImage: checkedIn ? "checkmark.circle.fill" : "circle")
                            }
                            .buttonStyle(.borderless)
                            .tint(checkedIn ? .green : .accentColor)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search member")
            .navigationTitle("Attendance")
            .onAppear {
                attendanceService.startListeningToday()
                memberService.startListening()
            }
            .onDisappear {
                attendanceService.stopListening()
                memberService.stopListening()
            }
        }
    }
}

#Preview {
    AttendanceView()
}

//
//  AttendanceService.swift
//  GymApp
//
//  Handles daily check-ins and attendance history ("Today Attendance" from notes).
//

import Foundation
import FirebaseFirestore

@MainActor
final class AttendanceService: ObservableObject {
    @Published var todaysAttendance: [Attendance] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListeningToday() {
        isLoading = true
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        listener = db.collection("attendance")
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.todaysAttendance = snapshot?.documents.compactMap { try? $0.data(as: Attendance.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Prevents duplicate check-ins for the same member on the same day.
    func hasCheckedInToday(memberId: String) -> Bool {
        todaysAttendance.contains { $0.memberId == memberId }
    }

    func checkIn(memberId: String) async throws {
        guard !hasCheckedInToday(memberId: memberId) else { return }
        let attendance = Attendance(memberId: memberId, date: Date(), checkInTime: Date())
        _ = try db.collection("attendance").addDocument(from: attendance)
    }

    func undoCheckIn(memberId: String) {
        guard let record = todaysAttendance.first(where: { $0.memberId == memberId }), let id = record.id else { return }
        db.collection("attendance").document(id).delete()
    }

    /// Fetches attendance history for a specific member (used in member detail / profile).
    func fetchHistory(memberId: String) async -> [Attendance] {
        do {
            let snapshot = try await db.collection("attendance")
                .whereField("memberId", isEqualTo: memberId)
                .order(by: "date", descending: true)
                .limit(to: 30)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Attendance.self) }
        } catch {
            errorMessage = error.localizedDescription
            return []
        }
    }
}

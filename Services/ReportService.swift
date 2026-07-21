//
//  ReportService.swift
//  GymApp
//
//  Generates a themed/branded balance sheet PDF using native PDFKit —
//  matches "Balance Sheet" + "Themed Report" from the notes. Runs entirely
//  on-device, no server needed.
//

import Foundation
import UIKit
import PDFKit

enum ReportService {
    static func generateBalanceSheetPDF(
        gymName: String,
        members: [Member],
        payments: [Payment],
        month: Int,
        year: Int
    ) -> URL? {
        let monthName = Calendar.current.monthSymbols[month - 1]
        let filteredPayments = payments.filter {
            let cal = Calendar.current
            return cal.component(.month, from: $0.paymentDate) == month &&
                   cal.component(.year, from: $0.paymentDate) == year
        }
        return renderBalanceSheetPDF(
            gymName: gymName,
            members: members,
            payments: filteredPayments,
            periodTitle: "\(monthName) \(year)",
            totalsLabel: "Total Collected This Month",
            emptyMessage: "No payments recorded for this month.",
            filename: "BalanceSheet-\(monthName)-\(year).pdf"
        )
    }

    /// Same report, but scoped to a single calendar day — for "download balance sheet for the day".
    static func generateDailyBalanceSheetPDF(
        gymName: String,
        members: [Member],
        payments: [Payment],
        date: Date
    ) -> URL? {
        let cal = Calendar.current
        let filteredPayments = payments.filter { cal.isDate($0.paymentDate, inSameDayAs: date) }
        let dayString = date.formatted(date: .abbreviated, time: .omitted)
        let fileDateString = date.formatted(.iso8601.year().month().day())
        return renderBalanceSheetPDF(
            gymName: gymName,
            members: members,
            payments: filteredPayments,
            periodTitle: dayString,
            totalsLabel: "Total Collected on \(dayString)",
            emptyMessage: "No payments recorded for this day.",
            filename: "BalanceSheet-\(fileDateString).pdf"
        )
    }

    // MARK: - Shared renderer

    private static func renderBalanceSheetPDF(
        gymName: String,
        members: [Member],
        payments: [Payment],
        periodTitle: String,
        totalsLabel: String,
        emptyMessage: String,
        filename: String
    ) -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let totalCollected = payments.reduce(0) { $0 + $1.amount }
        let totalDue = members.reduce(0) { $0 + $1.dueAmount }

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()

                var y: CGFloat = 40

                // Header — brand/theme area
                let titleFont = UIFont.boldSystemFont(ofSize: 22)
                let title = "\(gymName) — Balance Sheet"
                title.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: titleFont])
                y += 32

                let subtitleFont = UIFont.systemFont(ofSize: 14)
                periodTitle.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: subtitleFont, .foregroundColor: UIColor.darkGray])
                y += 30

                // Summary box
                let summaryFont = UIFont.systemFont(ofSize: 13)
                let boldSummaryFont = UIFont.boldSystemFont(ofSize: 13)
                "\(totalsLabel): ₹\(String(format: "%.2f", totalCollected))".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: boldSummaryFont])
                y += 18
                "Total Outstanding Due (all members): ₹\(String(format: "%.2f", totalDue))".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: boldSummaryFont, .foregroundColor: UIColor.red])
                y += 30

                // Table header
                let colX: [CGFloat] = [40, 250, 370, 470]
                let headerFont = UIFont.boldSystemFont(ofSize: 12)
                "Member".draw(at: CGPoint(x: colX[0], y: y), withAttributes: [.font: headerFont])
                "Date".draw(at: CGPoint(x: colX[1], y: y), withAttributes: [.font: headerFont])
                "Mode".draw(at: CGPoint(x: colX[2], y: y), withAttributes: [.font: headerFont])
                "Amount".draw(at: CGPoint(x: colX[3], y: y), withAttributes: [.font: headerFont])
                y += 16

                UIColor.lightGray.setStroke()
                let line = UIBezierPath()
                line.move(to: CGPoint(x: 40, y: y))
                line.addLine(to: CGPoint(x: pageWidth - 40, y: y))
                line.stroke()
                y += 10

                // Rows
                for payment in payments {
                    if y > pageHeight - 60 {
                        context.beginPage()
                        y = 40
                    }
                    let memberName = members.first(where: { $0.id == payment.memberId })?.name ?? "Unknown"
                    memberName.draw(at: CGPoint(x: colX[0], y: y), withAttributes: [.font: summaryFont])
                    payment.paymentDate.formatted(date: .abbreviated, time: .omitted).draw(at: CGPoint(x: colX[1], y: y), withAttributes: [.font: summaryFont])
                    payment.mode.rawValue.capitalized.draw(at: CGPoint(x: colX[2], y: y), withAttributes: [.font: summaryFont])
                    "₹\(String(format: "%.2f", payment.amount))".draw(at: CGPoint(x: colX[3], y: y), withAttributes: [.font: summaryFont])
                    y += 20
                }

                if payments.isEmpty {
                    emptyMessage.draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: summaryFont, .foregroundColor: UIColor.gray])
                }
            }
            return url
        } catch {
            print("PDF generation error: \(error)")
            return nil
        }
    }
}

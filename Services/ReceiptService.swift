//
//  ReceiptService.swift
//  GymApp
//
//  Generates a one-page PDF receipt for a single payment, right after it's
//  recorded — separate from ReportService, which generates multi-payment
//  balance sheets (monthly/daily) rather than a per-transaction receipt.
//

import Foundation
import UIKit

enum ReceiptService {
    static func generateReceiptPDF(
        gymName: String,
        member: Member,
        payment: Payment,
        dueBefore: Double,
        dueAfter: Double
    ) -> URL? {
        let pageWidth: CGFloat = 420   // roughly a large receipt/half-letter width
        let pageHeight: CGFloat = 560
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let receiptNumber = String((payment.id ?? UUID().uuidString).prefix(8)).uppercased()
        let filename = "Receipt-\(receiptNumber).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var y: CGFloat = 36

                let titleFont = UIFont.boldSystemFont(ofSize: 20)
                gymName.draw(at: CGPoint(x: 30, y: y), withAttributes: [.font: titleFont])
                y += 26

                let headerFont = UIFont.systemFont(ofSize: 12)
                "Payment Receipt".draw(at: CGPoint(x: 30, y: y), withAttributes: [.font: headerFont, .foregroundColor: UIColor.darkGray])
                y += 28

                UIColor.lightGray.setStroke()
                let topLine = UIBezierPath()
                topLine.move(to: CGPoint(x: 30, y: y))
                topLine.addLine(to: CGPoint(x: pageWidth - 30, y: y))
                topLine.stroke()
                y += 18

                let labelFont = UIFont.systemFont(ofSize: 12)
                let valueFont = UIFont.boldSystemFont(ofSize: 12)

                func row(_ label: String, _ value: String) {
                    label.draw(at: CGPoint(x: 30, y: y), withAttributes: [.font: labelFont, .foregroundColor: UIColor.darkGray])
                    let valueSize = (value as NSString).size(withAttributes: [.font: valueFont])
                    value.draw(at: CGPoint(x: pageWidth - 30 - valueSize.width, y: y), withAttributes: [.font: valueFont])
                    y += 22
                }

                row("Receipt No.", receiptNumber)
                row("Date", payment.paymentDate.formatted(date: .abbreviated, time: .shortened))
                row("Member", member.name)
                row("Phone", "\(member.dialCode) \(member.phone)")
                y += 6

                UIColor.lightGray.setStroke()
                let midLine = UIBezierPath()
                midLine.move(to: CGPoint(x: 30, y: y))
                midLine.addLine(to: CGPoint(x: pageWidth - 30, y: y))
                midLine.stroke()
                y += 18

                row("Payment Mode", payment.mode.rawValue.capitalized)
                row("Due Before", "₹\(String(format: "%.2f", dueBefore))")
                row("Amount Paid", "₹\(String(format: "%.2f", payment.amount))")
                row("Due After", "₹\(String(format: "%.2f", dueAfter))")
                y += 12

                let amountFont = UIFont.boldSystemFont(ofSize: 22)
                let amountText = "₹\(String(format: "%.2f", payment.amount)) Received"
                let amountSize = (amountText as NSString).size(withAttributes: [.font: amountFont])
                amountText.draw(at: CGPoint(x: (pageWidth - amountSize.width) / 2, y: y), withAttributes: [.font: amountFont, .foregroundColor: UIColor.systemGreen])
                y += 40

                let footerFont = UIFont.systemFont(ofSize: 10)
                "Thank you for your payment. This is a system-generated receipt.".draw(
                    at: CGPoint(x: 30, y: pageHeight - 40),
                    withAttributes: [.font: footerFont, .foregroundColor: UIColor.gray]
                )
            }
            return url
        } catch {
            print("Receipt PDF generation error: \(error)")
            return nil
        }
    }
}

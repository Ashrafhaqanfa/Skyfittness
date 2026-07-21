//
//  ComingSoonView.swift
//  GymApp
//
//  Shared placeholder for menu items that exist visually in the reference
//  design (AI Assistant, Subscription, SMS, Exercise/Measurement libraries,
//  QR check-in, Contact us, Communication) but need real backend work
//  (a subscription/billing provider, an SMS gateway, a barcode/QR library,
//  a support inbox, etc.) before they can do anything for real. Rather than
//  fake that functionality, each of these links here so it's honest about
//  what's built vs. what's still to come.
//

import SwiftUI

struct ComingSoonView: View {
    let title: String
    let icon: String
    var detail: String = "This feature needs a bit more backend work before it's ready. Let's build it properly when you're ready to prioritize it."

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.title3.bold())
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { ComingSoonView(title: "AI Assistant", icon: "sparkles") }
}

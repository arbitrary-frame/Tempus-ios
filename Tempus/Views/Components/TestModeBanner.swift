//
//  TestModeBanner.swift
//  Tempus
//
//  Test mode indicator banner
//

import SwiftUI

struct TestModeBanner: View {
    @AppStorage("isTestMode") private var isTestMode: Bool = false
    @State private var showingConfirmation = false

    var body: some View {
        if isTestMode {
            Button {
                showingConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "flask.fill")
                        .font(.caption.bold())

                    Text("🧪 TEST MODE")
                        .font(.caption.bold())

                    Spacer()

                    Text("Tap to Exit")
                        .font(.caption2)
                        .opacity(0.8)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.orange)
            }
            .buttonStyle(.plain)
            .alert("Switch to Production?", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Back to Production") {
                    isTestMode = false
                    HapticManager.shared.trigger(.success)
                }
            } message: {
                Text("You'll switch back to production mode with your real workout data. Test data will be hidden but preserved.")
            }
        }
    }
}

#Preview {
    VStack {
        TestModeBanner()
        Spacer()
    }
}

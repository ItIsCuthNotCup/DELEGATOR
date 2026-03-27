//
//  ConnectionBanner.swift
//  Delegator
//

import Combine
import SwiftUI

struct ConnectionBanner: View {
    let gatewayName: String
    let isConnected: Bool

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(gatewayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accentYellow)

                Text("DELEGATOR")
                    .font(Theme.statusLabel())
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isConnected ? Theme.onlineGreen : Theme.errorRed)
                        .frame(width: 6, height: 6)

                    Text(isConnected ? "ONLINE" : "OFFLINE")
                        .font(Theme.statusLabel())
                        .foregroundStyle(isConnected ? Theme.onlineGreen : Theme.errorRed)
                }

                Text(currentTime, format: .dateTime.hour().minute().second())
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, 8)
        .onReceive(timer) { currentTime = $0 }
    }
}

//
//  ServicesCard.swift
//  Delegator
//

import SwiftUI

struct ServicesCard: View {
    let services: ServicesSnapshot

    var body: some View {
        GlassCard(title: "Services") {
            VStack(alignment: .leading, spacing: 10) {
                // Gateway status
                GlassTile {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gateway")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(services.gatewayVersion)
                                .font(Theme.mono(10))
                                .foregroundStyle(Theme.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(services.gatewayRunning ? Theme.onlineGreen : Theme.errorRed)
                                    .frame(width: 6, height: 6)
                                Text(services.gatewayRunning ? "Running" : "Stopped")
                                    .font(Theme.statusLabel())
                                    .foregroundStyle(services.gatewayRunning ? Theme.onlineGreen : Theme.errorRed)
                            }
                            if services.gatewayUptime > 0 {
                                Text(formatUptime(services.gatewayUptime))
                                    .font(Theme.mono(9))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                        }
                    }
                }

                // Channels
                if !services.channels.isEmpty {
                    let columns = [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ]

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(services.channels) { channel in
                            GlassTile {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(channel.connected ? Theme.onlineGreen : Theme.errorRed)
                                        .frame(width: 5, height: 5)
                                    Text(channel.name)
                                        .font(Theme.mono(10))
                                        .foregroundStyle(Theme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 24 {
            return "\(hours / 24)d \(hours % 24)h"
        }
        return "\(hours)h \(minutes)m"
    }
}

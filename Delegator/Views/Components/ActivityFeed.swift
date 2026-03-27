//
//  ActivityFeed.swift
//  Delegator
//

import SwiftUI

struct ActivityFeed: View {
    let entries: [ActivityEntry]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(entries) { entry in
                ActivityRow(entry: entry)
            }
        }
    }
}

private struct ActivityRow: View {
    let entry: ActivityEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Timestamp
            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(Theme.mono(9))
                .foregroundStyle(Theme.textTertiary)
                .frame(width: 55, alignment: .leading)

            // Type badge
            Text(entry.type.displayName)
                .font(Theme.mono(8, weight: .bold))
                .foregroundStyle(badgeColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(badgeColor.opacity(0.15))
                }
                .frame(width: 38)

            // Summary
            Text(entry.summary)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    private var badgeColor: Color {
        switch entry.type {
        case .toolCall: return Theme.blue
        case .completion: return Theme.onlineGreen
        case .userMessage: return Theme.accentYellow
        case .assistantResponse: return Theme.purple
        case .error: return Theme.errorRed
        case .warning: return Theme.warningOrange
        case .system: return Theme.textTertiary
        }
    }
}

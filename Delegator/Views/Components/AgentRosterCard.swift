//
//  AgentRosterCard.swift
//  Delegator
//

import SwiftUI

struct AgentRosterCard: View {
    let agents: [Agent]

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        GlassCard(title: "Agents") {
            if agents.isEmpty {
                Text("No active agents")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(agents) { agent in
                        AgentTile(agent: agent)
                    }
                }
            }
        }
    }
}

private struct AgentTile: View {
    let agent: Agent
    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            GlassTile {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                            .overlay {
                                if agent.status == .active {
                                    Circle()
                                        .fill(Theme.onlineGreen.opacity(0.4))
                                        .frame(width: 12, height: 12)
                                        .scaleEffect(1.0)
                                }
                            }

                        Text(agent.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }

                    Text(agent.model)
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)

                    if isExpanded {
                        VStack(alignment: .leading, spacing: 4) {
                            tokenRow("IN", count: agent.tokenCount)
                            if let task = agent.currentTask {
                                Text(task)
                                    .font(Theme.mono(9))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
        .buttonStyle(.delegatorGlass)
    }

    private var statusColor: Color {
        switch agent.status {
        case .active: return Theme.onlineGreen
        case .idle: return Theme.textTertiary
        case .deployed: return Theme.blue
        case .offline: return Theme.errorRed
        }
    }

    private func tokenRow(_ label: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(Theme.mono(8, weight: .bold))
                .foregroundStyle(Theme.textTertiary)
            Text(formatTokenCount(count))
                .font(Theme.mono(9))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

private func formatTokenCount(_ count: Int) -> String {
    if count >= 1_000_000 {
        return String(format: "%.1fM", Double(count) / 1_000_000)
    } else if count >= 1_000 {
        return String(format: "%.1fK", Double(count) / 1_000)
    }
    return "\(count)"
}

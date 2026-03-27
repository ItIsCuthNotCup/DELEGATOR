//
//  CostOverviewCard.swift
//  Delegator
//

import SwiftUI

struct CostOverviewCard: View {
    let summary: CostSummary

    var body: some View {
        GlassCard(title: "Spend") {
            VStack(alignment: .leading, spacing: 12) {
                // Total cost
                Text(String(format: "$%.2f", summary.totalToday))
                    .font(Theme.mono(28, weight: .bold))
                    .foregroundStyle(Theme.accentYellow)

                // Token breakdown
                HStack(spacing: 16) {
                    tokenStat("TOKENS", count: summary.inputTokens, color: Theme.blue)
                    if summary.outputTokens > 0 {
                        tokenStat("OUTPUT", count: summary.outputTokens, color: Theme.purple)
                    }
                }

                // Per-model bars
                if !summary.perModel.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(sortedModels, id: \.key) { model, cost in
                            modelBar(model: model, cost: cost)
                        }
                    }
                }
            }
        }
    }

    private var sortedModels: [(key: String, value: Double)] {
        summary.perModel.sorted { $0.value > $1.value }
    }

    private func tokenStat(_ label: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.statusLabel())
                .foregroundStyle(Theme.textTertiary)
            Text(formatTokenCount(count))
                .font(Theme.mono(14, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    private func modelBar(model: String, cost: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(shortModelName(model))
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(String(format: "$%.3f", cost))
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.textTertiary)
            }

            GeometryReader { geo in
                let maxCost = summary.perModel.values.max() ?? 1
                let ratio = maxCost > 0 ? cost / maxCost : 0
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accentYellow.opacity(0.6))
                    .frame(width: geo.size.width * ratio)
            }
            .frame(height: 3)
        }
    }

    private func shortModelName(_ model: String) -> String {
        model
            .replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "gpt-", with: "")
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

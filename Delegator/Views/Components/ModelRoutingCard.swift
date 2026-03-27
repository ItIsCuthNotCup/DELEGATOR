//
//  ModelRoutingCard.swift
//  Delegator
//

import SwiftUI

struct ModelRoutingCard: View {
    let routing: ModelRoutingInfo

    var body: some View {
        GlassCard(title: "Model Routing") {
            VStack(alignment: .leading, spacing: 10) {
                // Primary model
                GlassTile {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PRIMARY")
                            .font(Theme.statusLabel())
                            .foregroundStyle(Theme.textTertiary)
                        Text(routing.primary)
                            .font(Theme.mono(13, weight: .semibold))
                            .foregroundStyle(Theme.accentYellow)
                    }
                }

                // Fallback chain
                if !routing.fallback.isEmpty {
                    GlassTile {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FALLBACK")
                                .font(Theme.statusLabel())
                                .foregroundStyle(Theme.textTertiary)
                            Text(routing.fallback.joined(separator: " → "))
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                // Aliases
                if !routing.aliases.isEmpty {
                    GlassTile {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ALIASES")
                                .font(Theme.statusLabel())
                                .foregroundStyle(Theme.textTertiary)
                            ForEach(Array(routing.aliases.keys.sorted()), id: \.self) { alias in
                                HStack {
                                    Text(alias)
                                        .font(Theme.mono(10, weight: .medium))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("→")
                                        .font(Theme.mono(10))
                                        .foregroundStyle(Theme.textTertiary)
                                    Text(routing.aliases[alias] ?? "")
                                        .font(Theme.mono(10))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

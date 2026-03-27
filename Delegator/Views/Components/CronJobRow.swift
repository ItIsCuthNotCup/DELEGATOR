//
//  CronJobRow.swift
//  Delegator
//

import SwiftUI

struct CronJobRow: View {
    let job: CronJob
    let onTrigger: () -> Void

    @State private var isTriggering = false
    @State private var flashColor: Color?

    var body: some View {
        GlassTile {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)

                    Text(job.humanSchedule)
                        .font(Theme.mono(10))
                        .foregroundStyle(Theme.textSecondary)

                    if let lastRun = job.lastRun {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(lastStatusColor)
                                .frame(width: 4, height: 4)
                            Text(lastRun, format: .relative(presentation: .named))
                                .font(Theme.mono(9))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    // Enabled indicator
                    Circle()
                        .fill(job.enabled ? Theme.onlineGreen : Theme.textTertiary)
                        .frame(width: 6, height: 6)

                    // Trigger button
                    Button {
                        isTriggering = true
                        onTrigger()
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            isTriggering = false
                        }
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.accentYellow)
                            .padding(8)
                            .background {
                                Circle()
                                    .fill(Theme.accentYellow.opacity(0.15))
                            }
                    }
                    .buttonStyle(.delegatorGlass)
                    .disabled(isTriggering)
                }
            }
        }
        .overlay {
            if let color = flashColor {
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .fill(color.opacity(0.2))
                    .allowsHitTesting(false)
            }
        }
    }

    private var lastStatusColor: Color {
        switch job.lastStatus {
        case .success: return Theme.onlineGreen
        case .failure: return Theme.errorRed
        case .running: return Theme.accentYellow
        case nil: return Theme.textTertiary
        }
    }
}

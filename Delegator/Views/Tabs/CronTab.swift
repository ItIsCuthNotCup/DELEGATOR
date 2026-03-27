//
//  CronTab.swift
//  Delegator
//

import SwiftUI

struct CronTab: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            Theme.baseBackground.ignoresSafeArea()
            AmbientOrbs()

            VStack(spacing: 0) {
                ConnectionBanner(
                    gatewayName: appState.gatewayName,
                    isConnected: appState.connectionState == .connected
                )

                if appState.cronJobs.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.textTertiary)
                        Text("No cron jobs")
                            .font(Theme.mono(12))
                            .foregroundStyle(Theme.textTertiary)
                        Text("Configure cron jobs in your gateway")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(appState.cronJobs) { job in
                                CronJobRow(job: job) {
                                    Task {
                                        _ = await appState.triggerCronJob(job)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Theme.cardPadding)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await appState.refreshAll()
                    }
                }
            }
        }
    }
}

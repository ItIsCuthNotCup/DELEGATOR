//
//  DashboardTab.swift
//  Delegator
//

import SwiftUI

struct DashboardTab: View {
    @Bindable var appState: AppState

    var body: some View {
        ZStack {
            // Background
            Theme.baseBackground.ignoresSafeArea()
            AmbientOrbs()

            VStack(spacing: 0) {
                ConnectionBanner(
                    gatewayName: appState.gatewayName,
                    isConnected: appState.connectionState == .connected
                )

                ScrollView {
                    VStack(spacing: Theme.cardSpacing) {
                        AgentRosterCard(agents: appState.agents)
                        CostOverviewCard(summary: appState.costSummary)
                        ServicesCard(services: appState.services)
                        ModelRoutingCard(routing: appState.modelRouting)
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

// MARK: - Ambient Glow Orbs

struct AmbientOrbs: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.accentYellow.opacity(0.04))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(Theme.blue.opacity(0.03))
                .frame(width: 350, height: 350)
                .blur(radius: 90)
                .offset(x: 150, y: 100)

            Circle()
                .fill(Theme.onlineGreen.opacity(0.025))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -80, y: 300)
        }
        .ignoresSafeArea()
    }
}

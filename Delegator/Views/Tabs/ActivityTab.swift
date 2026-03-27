//
//  ActivityTab.swift
//  Delegator
//

import SwiftUI

struct ActivityTab: View {
    @Bindable var appState: AppState
    @State private var showStopConfirmation = false

    var body: some View {
        ZStack {
            Theme.baseBackground.ignoresSafeArea()
            AmbientOrbs()

            VStack(spacing: 0) {
                ConnectionBanner(
                    gatewayName: appState.gatewayName,
                    isConnected: appState.connectionState == .connected
                )

                if appState.activityLog.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.textTertiary)
                        Text("No activity yet")
                            .font(Theme.mono(12))
                            .foregroundStyle(Theme.textTertiary)
                        Text("Events will appear here in real time")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        ActivityFeed(entries: appState.activityLog)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 80)
                    }
                }

                // Emergency Stop Button
                Button {
                    showStopConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("STOP AGENT")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.errorRed)
                    }
                    .shadow(color: Theme.errorRed.opacity(0.4), radius: 8, y: 4)
                }
                .buttonStyle(.delegatorGlass)
                .padding(.horizontal, Theme.cardPadding)
                .padding(.bottom, 8)
            }
        }
        .alert("Stop Agent", isPresented: $showStopConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Stop", role: .destructive) {
                Task { await appState.emergencyStop() }
            }
        } message: {
            Text("Stop the current agent run? This will abort all active processing.")
        }
    }
}

//
//  SettingsTab.swift
//  Delegator
//

import SwiftUI

struct SettingsTab: View {
    @Bindable var appState: AppState
    @State private var showDisconnectConfirmation = false

    var body: some View {
        ZStack {
            Theme.baseBackground.ignoresSafeArea()
            AmbientOrbs()

            ScrollView {
                VStack(spacing: Theme.cardSpacing) {
                    // Connection section
                    GlassCard(title: "Connection") {
                        VStack(alignment: .leading, spacing: 12) {
                            settingsRow("Gateway", value: maskedURL)
                            settingsRow("Token", value: maskedToken)
                            settingsRow("Status", value: appState.connectionState.rawValue.capitalized)

                            HStack(spacing: 10) {
                                Button {
                                    Task { await appState.connectFromKeychain() }
                                } label: {
                                    Text("Reconnect")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.accentYellow)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Theme.accentYellow.opacity(0.12))
                                        }
                                }
                                .buttonStyle(.delegatorGlass)

                                Button {
                                    showDisconnectConfirmation = true
                                } label: {
                                    Text("Disconnect")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Theme.errorRed)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Theme.errorRed.opacity(0.12))
                                        }
                                }
                                .buttonStyle(.delegatorGlass)
                            }
                        }
                    }

                    // About section
                    GlassCard(title: "About") {
                        VStack(alignment: .leading, spacing: 10) {
                            settingsRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            settingsRow("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")

                            GlassTile {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("MIT License")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("Based on OpenClaw Mission Control by Joey Rodriguez")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.cardPadding)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .alert("Disconnect", isPresented: $showDisconnectConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Disconnect & Remove", role: .destructive) {
                appState.disconnectAndClear()
            }
        } message: {
            Text("This will remove your gateway credentials. You'll need to reconnect.")
        }
    }

    private var maskedURL: String {
        KeychainManager.shared.gatewayURL ?? "Not configured"
    }

    private var maskedToken: String {
        guard let token = KeychainManager.shared.gatewayToken else { return "–" }
        let prefix = String(token.prefix(4))
        return "\(prefix)\(String(repeating: "•", count: 8))"
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
        }
    }
}

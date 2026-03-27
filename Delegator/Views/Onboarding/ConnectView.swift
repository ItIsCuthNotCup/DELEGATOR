//
//  ConnectView.swift
//  Delegator
//

import SwiftUI

struct ConnectView: View {
    @Bindable var appState: AppState

    @State private var gatewayURL = ""
    @State private var gatewayToken = ""
    @State private var hooksToken = ""
    @State private var showAdvanced = false
    @State private var showGatewayToken = false
    @State private var showHooksToken = false
    @State private var showQRScanner = false
    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.baseBackground.ignoresSafeArea()
            AmbientOrbs()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    // Logo area
                    VStack(spacing: 8) {
                        Text("DELEGATOR")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.accentYellow)

                        Text("Mission Control for OpenClaw")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }

                    // QR Scan option
                    Button {
                        showQRScanner = true
                    } label: {
                        GlassTile {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Scan QR Code")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.accentYellow)
                                    Text("Point your camera at the gateway QR")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 24))
                                    .foregroundStyle(Theme.accentYellow)
                            }
                        }
                    }
                    .buttonStyle(.delegatorGlass)

                    // Divider
                    HStack {
                        Rectangle().fill(Theme.glassStroke).frame(height: 0.5)
                        Text("OR")
                            .font(Theme.statusLabel())
                            .foregroundStyle(Theme.textTertiary)
                        Rectangle().fill(Theme.glassStroke).frame(height: 0.5)
                    }

                    // Manual entry
                    GlassCard(title: "Manual Connection") {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("GATEWAY URL")
                                    .font(Theme.statusLabel())
                                    .foregroundStyle(Theme.textTertiary)
                                TextField("wss://my-server.ts.net:18789", text: $gatewayURL)
                                    .font(Theme.mono(13))
                                    .foregroundStyle(Theme.textPrimary)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Theme.tileFill)
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Theme.tileBorder, lineWidth: 0.5)
                                    }
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("GATEWAY TOKEN")
                                    .font(Theme.statusLabel())
                                    .foregroundStyle(Theme.textTertiary)
                                HStack(spacing: 0) {
                                    Group {
                                        if showGatewayToken {
                                            TextField("Token", text: $gatewayToken)
                                        } else {
                                            SecureField("Token", text: $gatewayToken)
                                        }
                                    }
                                    .font(Theme.mono(13))
                                    .foregroundStyle(Theme.textPrimary)
                                    .textFieldStyle(.plain)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()

                                    Button {
                                        showGatewayToken.toggle()
                                    } label: {
                                        Image(systemName: showGatewayToken ? "eye.slash" : "eye")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.textTertiary)
                                    }
                                }
                                .padding(10)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.tileFill)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Theme.tileBorder, lineWidth: 0.5)
                                }
                            }

                            // Advanced section
                            DisclosureGroup(isExpanded: $showAdvanced) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("HOOKS TOKEN")
                                        .font(Theme.statusLabel())
                                        .foregroundStyle(Theme.textTertiary)
                                    HStack(spacing: 0) {
                                        Group {
                                            if showHooksToken {
                                                TextField("Optional", text: $hooksToken)
                                            } else {
                                                SecureField("Optional", text: $hooksToken)
                                            }
                                        }
                                        .font(Theme.mono(13))
                                        .foregroundStyle(Theme.textPrimary)
                                        .textFieldStyle(.plain)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()

                                        Button {
                                            showHooksToken.toggle()
                                        } label: {
                                            Image(systemName: showHooksToken ? "eye.slash" : "eye")
                                                .font(.system(size: 14))
                                                .foregroundStyle(Theme.textTertiary)
                                        }
                                    }
                                    .padding(10)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Theme.tileFill)
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(Theme.tileBorder, lineWidth: 0.5)
                                    }
                                }
                                .padding(.top, 8)
                            } label: {
                                Text("Advanced")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .tint(Theme.textTertiary)

                            // TLS warning
                            if !gatewayURL.isEmpty && isInsecureRemote {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Theme.warningOrange)
                                    Text("Unencrypted connections are not recommended for remote servers.")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Theme.warningOrange)
                                }
                            }

                            // Error message
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.errorRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Connect button
                            Button {
                                Task { await connectManually() }
                            } label: {
                                HStack {
                                    if isConnecting {
                                        ProgressView()
                                            .tint(Theme.baseBackground)
                                            .scaleEffect(0.8)
                                    }
                                    Text(isConnecting ? "Connecting..." : "Connect")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(Theme.baseBackground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(canConnect ? Theme.accentYellow : Theme.accentYellow.opacity(0.3))
                                }
                            }
                            .buttonStyle(.delegatorGlass)
                            .disabled(!canConnect || isConnecting)
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, Theme.cardPadding)
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { result in
                handleQRResult(result)
                showQRScanner = false
            }
        }
    }

    private var canConnect: Bool {
        !gatewayURL.trimmingCharacters(in: .whitespaces).isEmpty
        && !gatewayToken.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var isInsecureRemote: Bool {
        let url = gatewayURL.lowercased()
        let isInsecure = url.hasPrefix("ws://") || url.hasPrefix("http://")
        let isLocal = url.contains("127.0.0.1") || url.contains("localhost")
        return isInsecure && !isLocal
    }

    private func connectManually() async {
        isConnecting = true
        errorMessage = nil

        let success = await appState.connect(
            url: gatewayURL.trimmingCharacters(in: .whitespaces),
            token: gatewayToken.trimmingCharacters(in: .whitespaces),
            hooksToken: hooksToken.trimmingCharacters(in: .whitespaces)
        )

        isConnecting = false

        if !success {
            errorMessage = "Could not connect. Is your gateway running? Check your Tailscale connection and verify the token."
        }
    }

    private func handleQRResult(_ code: String) {
        // Try JSON format: { "url": "...", "token": "..." }
        if let data = code.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            if let url = json["url"] { gatewayURL = url }
            if let token = json["token"] { gatewayToken = token }
            if let hooks = json["hooks_token"] { hooksToken = hooks }
            if !gatewayURL.isEmpty && !gatewayToken.isEmpty {
                Task { await connectManually() }
            }
            return
        }

        // Try URL format: delegator://connect?url=...&token=...
        if let components = URLComponents(string: code),
           let items = components.queryItems {
            for item in items {
                switch item.name {
                case "url": gatewayURL = item.value ?? ""
                case "token": gatewayToken = item.value ?? ""
                case "hooks_token": hooksToken = item.value ?? ""
                default: break
                }
            }
            if !gatewayURL.isEmpty && !gatewayToken.isEmpty {
                Task { await connectManually() }
            }
        }
    }
}

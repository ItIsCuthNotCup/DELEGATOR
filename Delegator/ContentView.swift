//
//  ContentView.swift
//  Delegator
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isOnboarding {
            ConnectView(appState: appState)
        } else {
            MainTabView(appState: appState)
                .task {
                    if appState.connectionState == .disconnected {
                        await appState.connectFromKeychain()
                    }
                }
        }
    }
}

struct MainTabView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView {
            DashboardTab(appState: appState)
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.3.group")
                }

            ActivityTab(appState: appState)
                .tabItem {
                    Label("Activity", systemImage: "waveform")
                }

            CronTab(appState: appState)
                .tabItem {
                    Label("Cron", systemImage: "clock.arrow.circlepath")
                }

            SettingsTab(appState: appState)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Theme.accentYellow)
    }
}

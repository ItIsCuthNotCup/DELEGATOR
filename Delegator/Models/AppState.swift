//
//  AppState.swift
//  Delegator
//

import Foundation
import SwiftUI

func debugWrite(_ message: String) {
    #if DEBUG
    let line = "\(Date()): \(message)\n"
    let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Delegator", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent("delegator_debug.log")
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: url)
        }
    }
    #endif
}

@Observable
@MainActor
final class AppState {
    // MARK: - Connection State

    enum ConnectionState: String {
        case disconnected, connecting, connected
    }

    var connectionState: ConnectionState = .disconnected
    var isOnboarding: Bool

    // MARK: - Data

    var agents: [Agent] = []
    var sessions: [Session] = []
    var activityLog: [ActivityEntry] = []
    var cronJobs: [CronJob] = []
    var services: ServicesSnapshot = .empty
    var modelRouting: ModelRoutingInfo = .empty
    var costSummary: CostSummary = CostSummary()
    var gatewayName: String = "Gateway"

    // MARK: - Connection

    private(set) var connection: GatewayConnection?
    private var pollingTask: Task<Void, Never>?
    private var isPolling = false

    // MARK: - Init

    init() {
        self.isOnboarding = !KeychainManager.shared.hasCredentials
    }

    // MARK: - Connect

    func connect(url: String, token: String, hooksToken: String = "") async -> Bool {
        connectionState = .connecting
        let conn = GatewayConnection(url: url, gatewayToken: token, hooksToken: hooksToken)

        let healthy = await conn.checkHealth()
        guard healthy else {
            connectionState = .disconnected
            return false
        }

        // Save credentials
        KeychainManager.shared.gatewayURL = url
        KeychainManager.shared.gatewayToken = token
        if !hooksToken.isEmpty {
            KeychainManager.shared.hooksToken = hooksToken
        }

        self.connection = conn
        connectionState = .connected
        isOnboarding = false

        // Setup WebSocket events
        conn.onEvent = { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleEvent(event)
            }
        }

        // Connect WebSocket
        conn.connect()

        // Start polling for data
        startPolling()

        // Initial fetch
        await refreshAll()

        return true
    }

    func connectFromKeychain() async {
        guard let url = KeychainManager.shared.gatewayURL,
              let token = KeychainManager.shared.gatewayToken else {
            isOnboarding = true
            return
        }

        let hooksToken = KeychainManager.shared.hooksToken ?? ""
        let success = await connect(url: url, token: token, hooksToken: hooksToken)
        if !success {
            connectionState = .disconnected
        }
    }

    func disconnect() {
        pollingTask?.cancel()
        connection?.disconnect()
        connection = nil
        connectionState = .disconnected
        agents = []
        sessions = []
        cronJobs = []
        services = .empty
        modelRouting = .empty
        costSummary = CostSummary()
    }

    func disconnectAndClear() {
        disconnect()
        KeychainManager.shared.clearAll()
        isOnboarding = true
    }

    // MARK: - Lifecycle

    func handleForeground() {
        connection?.connect()
        startPolling()
        Task { await refreshAll() }
    }

    func handleBackground() {
        pollingTask?.cancel()
        connection?.disconnect()
    }

    // MARK: - Polling

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                await self?.refreshAll()
            }
        }
    }

    func refreshAll() async {
        guard let connection, connectionState == .connected else { return }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchSessions(connection) }
            group.addTask { await self.fetchGatewayHealth(connection) }
            group.addTask { await self.fetchCronJobs(connection) }
        }
    }

    // MARK: - Data Fetching

    private func fetchSessions(_ conn: GatewayConnection) async {
        do {
            let data = try await conn.invokeTool(name: "sessions_list")
            if let parsed = parseToolResult(data) {
                if let sessionsData = parsed.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    let wrapper = try decoder.decode(SessionsListResponse.self, from: sessionsData)
                    let decoded = wrapper.sessions
                    self.sessions = decoded
                    self.costSummary = CostCalculator.aggregateCost(sessions: decoded)

                    // Derive agents from sessions
                    self.agents = decoded.map { session in
                        Agent(
                            id: session.id,
                            name: session.agentName,
                            role: session.channel ?? "",
                            model: session.model,
                            status: session.status == "running" ? .active : .idle,
                            tokenCount: session.totalTokens,
                            sessionDuration: session.updatedAt.map { ($0 - session.startedAt) / 1000 } ?? 0,
                            fallbackChain: [],
                            currentTask: nil
                        )
                    }

                    // Derive model routing from sessions
                    let models = Set(decoded.map(\.model))
                    if !models.isEmpty {
                        self.modelRouting = ModelRoutingInfo(
                            primary: decoded.first?.model ?? "–",
                            fallback: [],
                            aliases: [:]
                        )
                    }

                    debugWrite("[Delegator:sessions] decoded \(decoded.count) sessions")
                }
            }
        } catch {
            debugWrite("[Delegator:sessions] FAILED: \(error)")
            appendActivity(.error, summary: "Failed to fetch sessions: \(error.localizedDescription)")
        }
    }

    private func fetchGatewayHealth(_ conn: GatewayConnection) async {
        let healthy = await conn.checkHealth()
        self.services = ServicesSnapshot(
            gatewayRunning: healthy,
            gatewayVersion: "OpenClaw",
            gatewayUptime: 0,
            channels: sessions.compactMap { session in
                guard let channel = session.channel else { return nil }
                return ServicesSnapshot.ChannelStatus(
                    name: channel,
                    connected: session.status == "running"
                )
            }
        )
    }

    private func fetchCronJobs(_ conn: GatewayConnection) async {
        do {
            let data = try await conn.invokeTool(name: "cron", input: ["action": "list"])
            if let parsed = parseToolResult(data) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let cronData = parsed.data(using: .utf8),
                   let decoded = try? decoder.decode([CronJob].self, from: cronData) {
                    self.cronJobs = decoded
                }
            }
        } catch {
            // cron tool may not be available — silently ignore 404s
            if case GatewayError.httpError(404) = error { return }
            appendActivity(.error, summary: "Failed to fetch cron jobs: \(error.localizedDescription)")
        }
    }

    // MARK: - Actions

    func triggerCronJob(_ job: CronJob) async -> Bool {
        guard let connection else { return false }
        do {
            _ = try await connection.invokeTool(name: "cron", input: ["action": "run", "name": job.name])
            HapticManager.notification(.success)
            appendActivity(.system, summary: "Triggered cron job: \(job.name)")
            return true
        } catch {
            HapticManager.notification(.error)
            appendActivity(.error, summary: "Failed to trigger \(job.name): \(error.localizedDescription)")
            return false
        }
    }

    func emergencyStop() async {
        HapticManager.emergencyStop()
        guard let connection else { return }

        // Try WebSocket abort first, fall back to HTTP hook
        do {
            _ = try await connection.postHook(path: "agent", payload: ["action": "abort"])
            appendActivity(.warning, summary: "Emergency stop triggered")
        } catch {
            appendActivity(.error, summary: "Emergency stop failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Events

    private func handleEvent(_ event: GatewayEvent) {
        let type: ActivityEntry.ActivityType
        switch event.name {
        case "agent": type = .toolCall
        case "chat": type = .assistantResponse
        case "health": type = .system
        case "cron": type = .system
        case "exec.approval.requested": type = .warning
        case "tick": return // Silent
        default: type = .system
        }

        let summary = (event.data["summary"] as? String)
            ?? (event.data["message"] as? String)
            ?? event.name

        appendActivity(type, summary: summary)

        // Refresh on significant events
        if ["agent", "cron", "health"].contains(event.name) {
            Task { await refreshAll() }
        }
    }

    func appendActivity(_ type: ActivityEntry.ActivityType, summary: String) {
        let entry = ActivityEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            type: type,
            summary: summary
        )
        activityLog.insert(entry, at: 0)
        if activityLog.count > 500 {
            activityLog = Array(activityLog.prefix(500))
        }
    }

    // MARK: - Helpers

    private func parseToolResult(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let content = result["content"] as? [[String: Any]],
              let first = content.first,
              let text = first["text"] as? String else {
            // Try direct text result
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let text = json["text"] as? String {
                return text
            }
            return String(data: data, encoding: .utf8)
        }
        return text
    }
}

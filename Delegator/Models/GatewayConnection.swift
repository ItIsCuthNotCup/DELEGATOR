//
//  GatewayConnection.swift
//  Delegator
//

import Foundation

final class GatewayConnection: @unchecked Sendable {
    enum State: String {
        case disconnected, connecting, connected
    }

    private(set) var state: State = .disconnected

    let host: String
    let port: Int
    let useTLS: Bool
    let gatewayToken: String
    let hooksToken: String

    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession
    private var pendingRequests: [String: CheckedContinuation<Data, Error>] = [:]
    private var reconnectAttempt = 0
    private var reconnectTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?

    var onEvent: ((GatewayEvent) -> Void)?

    // MARK: - Init

    init(host: String, port: Int = 18789, useTLS: Bool, gatewayToken: String, hooksToken: String = "") {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.gatewayToken = gatewayToken
        self.hooksToken = hooksToken
        self.urlSession = URLSession(configuration: .default)
    }

    convenience init(url: String, gatewayToken: String, hooksToken: String = "") {
        var cleanURL = url
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "wss://", with: "")
            .replacingOccurrences(of: "ws://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")

        if cleanURL.hasSuffix("/") {
            cleanURL = String(cleanURL.dropLast())
        }

        let useTLS = url.hasPrefix("wss://") || url.hasPrefix("https://")
            || (!url.hasPrefix("ws://") && !url.hasPrefix("http://"))

        let components = cleanURL.split(separator: ":")
        let host = String(components[0])
        let port = components.count > 1 ? Int(components[1]) ?? 18789 : 18789

        self.init(host: host, port: port, useTLS: useTLS, gatewayToken: gatewayToken, hooksToken: hooksToken)
    }

    // MARK: - HTTP Base URL

    private var httpBaseURL: String {
        let scheme = useTLS ? "https" : "http"
        return "\(scheme)://\(host):\(port)"
    }

    private var wsBaseURL: String {
        let scheme = useTLS ? "wss" : "ws"
        return "\(scheme)://\(host):\(port)"
    }

    // MARK: - Health Check

    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(httpBaseURL)/health") else { return false }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await urlSession.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "nil"
            debugWrite("[Delegator:health] GET \(url) → \(statusCode): \(body.prefix(200))")
            return statusCode == 200
        } catch {
            debugWrite("[Delegator:health] GET \(url) FAILED: \(error)")
            return false
        }
    }

    // MARK: - Tool Invocation

    func invokeTool(name: String, input: [String: Any] = [:]) async throws -> Data {
        guard let url = URL(string: "\(httpBaseURL)/tools/invoke") else {
            throw GatewayError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("Bearer \(gatewayToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["tool": name, "input": input]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GatewayError.invalidResponse
        }

        debugWrite("[Delegator:invoke] POST /tools/invoke tool=\(name) → \(httpResponse.statusCode)")

        if httpResponse.statusCode == 401 {
            throw GatewayError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "nil"
            debugWrite("[Delegator:invoke] error body: \(body.prefix(300))")
            throw GatewayError.httpError(httpResponse.statusCode)
        }

        return data
    }

    // MARK: - Hooks

    func postHook(path: String, payload: [String: Any] = [:]) async throws -> Data {
        let token = hooksToken.isEmpty ? gatewayToken : hooksToken
        guard let url = URL(string: "\(httpBaseURL)/hooks/\(path)") else {
            throw GatewayError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GatewayError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return data
    }

    // MARK: - Chat

    func sendChat(message: String, model: String? = nil) async throws -> Data {
        guard let url = URL(string: "\(httpBaseURL)/v1/chat/completions") else {
            throw GatewayError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("Bearer \(gatewayToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "messages": [["role": "user", "content": message]]
        ]
        if let model { body["model"] = model }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GatewayError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    // MARK: - WebSocket

    func connect() {
        guard state != .connected && state != .connecting else { return }
        state = .connecting

        guard let url = URL(string: "\(wsBaseURL)/") else {
            state = .disconnected
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(gatewayToken)", forHTTPHeaderField: "Authorization")

        webSocket = urlSession.webSocketTask(with: request)
        webSocket?.resume()

        state = .connected
        reconnectAttempt = 0

        startReceiveLoop()
        startPingLoop()
    }

    func disconnect() {
        receiveTask?.cancel()
        pingTask?.cancel()
        reconnectTask?.cancel()
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        state = .disconnected
    }

    private func startReceiveLoop() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                guard let ws = self.webSocket else { break }
                do {
                    let message = try await ws.receive()
                    switch message {
                    case .string(let text):
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    if !Task.isCancelled {
                        self.state = .disconnected
                        self.scheduleReconnect()
                    }
                    break
                }
            }
        }
    }

    private func startPingLoop() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                self?.webSocket?.sendPing { _ in }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "event":
            if let eventName = json["event"] as? String,
               let eventData = json["data"] as? [String: Any] {
                let event = GatewayEvent(name: eventName, data: eventData)
                onEvent?(event)
            }
        case "res":
            if let id = json["id"] as? String,
               let continuation = pendingRequests.removeValue(forKey: id) {
                continuation.resume(returning: data)
            }
        default:
            break
        }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            guard let self else { return }
            let delay = min(pow(2.0, Double(self.reconnectAttempt)), 60)
            self.reconnectAttempt += 1
            try? await Task.sleep(for: .seconds(delay))
            if !Task.isCancelled {
                self.connect()
            }
        }
    }
}

// MARK: - Supporting Types

struct GatewayEvent {
    let name: String
    let data: [String: Any]
}

enum GatewayError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid gateway URL"
        case .invalidResponse: return "Invalid response from gateway"
        case .unauthorized: return "Invalid token — check your gateway credentials"
        case .httpError(let code): return "Gateway returned HTTP \(code)"
        }
    }
}

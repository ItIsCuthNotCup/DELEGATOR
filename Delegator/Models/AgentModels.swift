//
//  AgentModels.swift
//  Delegator
//

import Foundation
import SwiftData

// MARK: - Agent

struct Agent: Identifiable, Codable {
    let id: String
    var name: String
    var role: String
    var model: String
    var status: AgentStatus
    var tokenCount: Int
    var sessionDuration: TimeInterval
    var fallbackChain: [String]
    var currentTask: String?

    enum AgentStatus: String, Codable {
        case active, idle, deployed, offline
    }
}

// MARK: - Session (matches OpenClaw Gateway sessions_list response)

struct SessionsListResponse: Codable {
    let count: Int
    let sessions: [Session]
}

struct Session: Identifiable, Codable {
    var id: String { sessionId }
    let sessionId: String
    var key: String
    var kind: String?
    var channel: String?
    var model: String
    var totalTokens: Int
    var contextTokens: Int?
    var estimatedCostUsd: Double
    var status: String
    var startedAt: Double // epoch milliseconds from gateway
    var updatedAt: Double?
    var lastChannel: String?

    var startedAtDate: Date {
        Date(timeIntervalSince1970: startedAt / 1000)
    }

    /// Derive agent name from the key (e.g. "agent:main:main" → "main")
    var agentName: String {
        let parts = key.split(separator: ":")
        return parts.count >= 2 ? String(parts[1]) : key
    }
}

// MARK: - Activity Entry

struct ActivityEntry: Identifiable, Codable {
    let id: String
    var timestamp: Date
    var type: ActivityType
    var summary: String
    var detail: String?

    enum ActivityType: String, Codable {
        case toolCall, completion, userMessage, assistantResponse, error, warning, system

        var displayName: String {
            switch self {
            case .toolCall: return "TOOL"
            case .completion: return "DONE"
            case .userMessage: return "USER"
            case .assistantResponse: return "ASST"
            case .error: return "ERR"
            case .warning: return "WARN"
            case .system: return "SYS"
            }
        }
    }
}

// MARK: - Cron Job

struct CronJob: Identifiable, Codable {
    let id: String
    var name: String
    var schedule: String
    var enabled: Bool
    var lastRun: Date?
    var lastStatus: CronStatus?

    enum CronStatus: String, Codable {
        case success, failure, running
    }

    var humanSchedule: String {
        cronToHuman(schedule)
    }
}

// MARK: - Services Snapshot

struct ServicesSnapshot: Codable {
    var gatewayRunning: Bool
    var gatewayVersion: String
    var gatewayUptime: TimeInterval
    var channels: [ChannelStatus]

    struct ChannelStatus: Identifiable, Codable {
        var id: String { name }
        var name: String
        var connected: Bool
    }

    static let empty = ServicesSnapshot(
        gatewayRunning: false,
        gatewayVersion: "–",
        gatewayUptime: 0,
        channels: []
    )
}

// MARK: - Model Routing

struct ModelRoutingInfo: Codable {
    var primary: String
    var fallback: [String]
    var aliases: [String: String]

    static let empty = ModelRoutingInfo(primary: "–", fallback: [], aliases: [:])
}

// MARK: - Cost Summary

struct CostSummary {
    var totalToday: Double = 0
    var inputTokens: Int = 0
    var outputTokens: Int = 0
    var perModel: [String: Double] = [:]
}

// MARK: - SwiftData Persistence

@Model
final class CostRecord {
    var date: Date
    var totalCost: Double
    var inputTokens: Int
    var outputTokens: Int

    init(date: Date, totalCost: Double, inputTokens: Int, outputTokens: Int) {
        self.date = date
        self.totalCost = totalCost
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
    }
}

// MARK: - Cron Parsing

func cronToHuman(_ expression: String) -> String {
    let parts = expression.components(separatedBy: " ")
    guard parts.count >= 5 else { return expression }

    let minute = parts[0]
    let hour = parts[1]
    let dom = parts[2]
    let month = parts[3]
    let dow = parts[4]

    if minute == "*" && hour == "*" && dom == "*" && month == "*" && dow == "*" {
        return "Every minute"
    }
    if minute.hasPrefix("*/"), hour == "*", dom == "*", month == "*", dow == "*" {
        let interval = minute.dropFirst(2)
        return "Every \(interval) minutes"
    }
    if hour == "*" && dom == "*" && month == "*" && dow == "*" {
        return "Hourly at :\(minute.count == 1 ? "0\(minute)" : minute)"
    }
    if dom == "*" && month == "*" && dow == "*" {
        return "Daily at \(hour):\(minute.count == 1 ? "0\(minute)" : minute)"
    }
    return expression
}

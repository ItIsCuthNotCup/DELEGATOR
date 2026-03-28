//
//  DelegatorTests.swift
//  DelegatorTests
//

import XCTest
@testable import Delegator

final class CostCalculatorTests: XCTestCase {

    func testKnownModelPricing() {
        // Claude Opus 4.6: $15/1M input, $75/1M output
        let cost = CostCalculator.cost(model: "claude-opus-4-6", inputTokens: 1_000_000, outputTokens: 1_000_000)
        XCTAssertEqual(cost, 90.0, accuracy: 0.001)
    }

    func testUnknownModelDefaultsToSonnetPricing() {
        // Unknown model should default to $3/1M input, $15/1M output
        let cost = CostCalculator.cost(model: "unknown-model-xyz", inputTokens: 1_000_000, outputTokens: 1_000_000)
        XCTAssertEqual(cost, 18.0, accuracy: 0.001)
    }

    func testZeroTokensReturnsZeroCost() {
        let cost = CostCalculator.cost(model: "gpt-4o", inputTokens: 0, outputTokens: 0)
        XCTAssertEqual(cost, 0.0, accuracy: 0.001)
    }

    func testAggregateCostFromSessions() {
        let sessions = [
            Session(
                sessionId: "s1", key: "agent:main:main", kind: nil, channel: "slack",
                model: "claude-sonnet-4-6", totalTokens: 5000, contextTokens: nil,
                estimatedCostUsd: 0.12, status: "running", startedAt: 1711600000000,
                updatedAt: 1711600060000, lastChannel: nil
            ),
            Session(
                sessionId: "s2", key: "agent:coder:main", kind: nil, channel: "discord",
                model: "gpt-4o", totalTokens: 3000, contextTokens: nil,
                estimatedCostUsd: 0.08, status: "idle", startedAt: 1711600000000,
                updatedAt: nil, lastChannel: nil
            ),
        ]

        let summary = CostCalculator.aggregateCost(sessions: sessions)
        XCTAssertEqual(summary.totalToday, 0.20, accuracy: 0.001)
        XCTAssertEqual(summary.inputTokens, 8000)
        XCTAssertEqual(summary.perModel["claude-sonnet-4-6"], 0.12, accuracy: 0.001)
        XCTAssertEqual(summary.perModel["gpt-4o"], 0.08, accuracy: 0.001)
    }

    func testAggregateCostEmptySessions() {
        let summary = CostCalculator.aggregateCost(sessions: [])
        XCTAssertEqual(summary.totalToday, 0.0)
        XCTAssertEqual(summary.inputTokens, 0)
        XCTAssertTrue(summary.perModel.isEmpty)
    }
}

final class CronParsingTests: XCTestCase {

    func testEveryMinute() {
        XCTAssertEqual(cronToHuman("* * * * *"), "Every minute")
    }

    func testEveryNMinutes() {
        XCTAssertEqual(cronToHuman("*/5 * * * *"), "Every 5 minutes")
        XCTAssertEqual(cronToHuman("*/15 * * * *"), "Every 15 minutes")
    }

    func testHourly() {
        XCTAssertEqual(cronToHuman("30 * * * *"), "Hourly at :30")
        XCTAssertEqual(cronToHuman("0 * * * *"), "Hourly at :00")
    }

    func testDaily() {
        XCTAssertEqual(cronToHuman("0 9 * * *"), "Daily at 9:00")
        XCTAssertEqual(cronToHuman("30 14 * * *"), "Daily at 14:30")
    }

    func testPassthroughForComplexExpressions() {
        let expr = "0 9 1 * 1-5"
        XCTAssertEqual(cronToHuman(expr), expr)
    }

    func testInvalidExpression() {
        XCTAssertEqual(cronToHuman("invalid"), "invalid")
    }
}

final class SessionModelTests: XCTestCase {

    func testAgentNameParsing() {
        let session = Session(
            sessionId: "s1", key: "agent:main:main", kind: nil, channel: nil,
            model: "claude-sonnet-4-6", totalTokens: 0, contextTokens: nil,
            estimatedCostUsd: 0, status: "idle", startedAt: 1711600000000,
            updatedAt: nil, lastChannel: nil
        )
        XCTAssertEqual(session.agentName, "main")
    }

    func testAgentNameFallsBackToFullKey() {
        let session = Session(
            sessionId: "s1", key: "single", kind: nil, channel: nil,
            model: "gpt-4o", totalTokens: 0, contextTokens: nil,
            estimatedCostUsd: 0, status: "idle", startedAt: 1711600000000,
            updatedAt: nil, lastChannel: nil
        )
        XCTAssertEqual(session.agentName, "single")
    }

    func testStartedAtDateConversion() {
        let session = Session(
            sessionId: "s1", key: "agent:test:main", kind: nil, channel: nil,
            model: "gpt-4o", totalTokens: 0, contextTokens: nil,
            estimatedCostUsd: 0, status: "idle", startedAt: 1711600000000,
            updatedAt: nil, lastChannel: nil
        )
        // 1711600000 epoch seconds = 2024-03-28 ~04:26 UTC
        XCTAssertEqual(session.startedAtDate.timeIntervalSince1970, 1711600000, accuracy: 1)
    }

    func testSessionDecodingFromJSON() throws {
        let json = """
        {
            "count": 1,
            "sessions": [{
                "sessionId": "abc123",
                "key": "agent:worker:main",
                "model": "claude-sonnet-4-6",
                "totalTokens": 12345,
                "estimatedCostUsd": 0.45,
                "status": "running",
                "startedAt": 1711600000000
            }]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(SessionsListResponse.self, from: json)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.sessions.first?.sessionId, "abc123")
        XCTAssertEqual(decoded.sessions.first?.agentName, "worker")
        XCTAssertEqual(decoded.sessions.first?.totalTokens, 12345)
    }
}

final class ModelRoutingTests: XCTestCase {

    func testEmptyDefault() {
        let empty = ModelRoutingInfo.empty
        XCTAssertEqual(empty.primary, "–")
        XCTAssertTrue(empty.fallback.isEmpty)
        XCTAssertTrue(empty.aliases.isEmpty)
    }
}

final class ServicesSnapshotTests: XCTestCase {

    func testEmptyDefault() {
        let empty = ServicesSnapshot.empty
        XCTAssertFalse(empty.gatewayRunning)
        XCTAssertEqual(empty.gatewayVersion, "–")
        XCTAssertTrue(empty.channels.isEmpty)
    }

    func testChannelStatusIdentifiable() {
        let channel = ServicesSnapshot.ChannelStatus(name: "slack", connected: true)
        XCTAssertEqual(channel.id, "slack")
    }
}

final class ActivityEntryTests: XCTestCase {

    func testDisplayNames() {
        XCTAssertEqual(ActivityEntry.ActivityType.toolCall.displayName, "TOOL")
        XCTAssertEqual(ActivityEntry.ActivityType.error.displayName, "ERR")
        XCTAssertEqual(ActivityEntry.ActivityType.warning.displayName, "WARN")
        XCTAssertEqual(ActivityEntry.ActivityType.system.displayName, "SYS")
        XCTAssertEqual(ActivityEntry.ActivityType.assistantResponse.displayName, "ASST")
    }
}

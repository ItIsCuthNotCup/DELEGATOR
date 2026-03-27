//
//  CostCalculator.swift
//  Delegator
//

import Foundation

enum CostCalculator {
    // Pricing per 1M tokens (input / output)
    private static let pricing: [String: (input: Double, output: Double)] = [
        "claude-opus-4-6": (15.0, 75.0),
        "claude-sonnet-4-6": (3.0, 15.0),
        "claude-haiku-4-5": (0.80, 4.0),
        "gpt-4o": (2.50, 10.0),
        "gpt-4o-mini": (0.15, 0.60),
        "o1": (15.0, 60.0),
        "o1-mini": (1.10, 4.40),
        "o3": (2.0, 8.0),
        "o3-mini": (1.10, 4.40),
        "o4-mini": (1.10, 4.40),
    ]

    static func cost(model: String, inputTokens: Int, outputTokens: Int) -> Double {
        let normalizedModel = model.lowercased()
        let rates = pricing.first { normalizedModel.contains($0.key) }?.value
            ?? (input: 3.0, output: 15.0) // Default to Sonnet-class pricing

        let inputCost = Double(inputTokens) / 1_000_000 * rates.input
        let outputCost = Double(outputTokens) / 1_000_000 * rates.output
        return inputCost + outputCost
    }

    static func aggregateCost(sessions: [Session]) -> CostSummary {
        var summary = CostSummary()
        var perModel: [String: Double] = [:]

        for session in sessions {
            // Use gateway-provided cost when available
            let sessionCost = session.estimatedCostUsd
            summary.totalToday += sessionCost
            summary.inputTokens += session.totalTokens // Gateway only provides total
            perModel[session.model, default: 0] += sessionCost
        }

        summary.perModel = perModel
        return summary
    }
}

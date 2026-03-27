//
//  Theme.swift
//  Delegator
//
//  Ported from OpenClaw Mission Control by Joey Rodriguez (MIT)
//

import SwiftUI

enum Theme {
    // MARK: - Backgrounds
    static let baseBackground = Color(hex: "050506")
    static let glassFill = Color(hex: "161619", alpha: 0.92)
    static let glassOverlay = Color.white.opacity(0.045)
    static let glassStroke = Color.white.opacity(0.12)
    static let topHighlight = Color.white.opacity(0.18)

    // MARK: - Accents
    static let accentYellow = Color(hex: "FFD60A")
    static let onlineGreen = Color(hex: "30D158")
    static let errorRed = Color(hex: "FF453A")
    static let warningOrange = Color(hex: "FF9F0A")
    static let blue = Color(hex: "0A84FF")
    static let purple = Color(hex: "BF5AF2")
    static let teal = Color(hex: "64D2FF")

    // MARK: - Text
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary = Color.white.opacity(0.35)

    // MARK: - Tiles
    static let tileFill = Color.white.opacity(0.03)
    static let tileBorder = Color.white.opacity(0.05)

    // MARK: - Layout
    static let cardRadius: CGFloat = 16
    static let tileRadius: CGFloat = 10
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 14

    // MARK: - Typography
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func cardTitle() -> Font {
        .system(size: 11, weight: .semibold)
    }

    static func statusLabel() -> Font {
        .system(size: 10, weight: .bold, design: .monospaced)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: alpha
        )
    }
}

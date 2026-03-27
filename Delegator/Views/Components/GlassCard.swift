//
//  GlassCard.swift
//  Delegator
//
//  Ported from OpenClaw Mission Control by Joey Rodriguez (MIT)
//

import SwiftUI

struct GlassCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content

    init(title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        cardContent
            .background { glassFillLayer }
            .background { gradientLayer }
            .background { materialLayer }
            .overlay { strokeOverlay }
            .overlay { highlightOverlay }
            .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
    }

    // MARK: - Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: Theme.cardSpacing) {
            if let title {
                Text(title)
                    .font(Theme.cardTitle())
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.textSecondary)
            }
            content()
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Backgrounds

    private var glassFillLayer: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius)
            .fill(Theme.glassFill)
    }

    private var gradientLayer: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.04),
                        Color.white.opacity(0.01),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var materialLayer: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius)
            .fill(.ultraThinMaterial)
            .opacity(0.12)
    }

    // MARK: - Overlays

    private var strokeOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius)
            .strokeBorder(Theme.glassStroke, lineWidth: 0.5)
    }

    private var highlightOverlay: some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Theme.topHighlight.opacity(0.6),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
    }
}

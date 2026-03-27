//
//  GlassTile.swift
//  Delegator
//
//  Ported from OpenClaw Mission Control by Joey Rodriguez (MIT)
//

import SwiftUI

struct GlassTile<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .fill(Theme.tileFill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.tileRadius)
                    .strokeBorder(Theme.tileBorder, lineWidth: 0.5)
            }
    }
}

// MARK: - Glass Button Style

struct DelegatorGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == DelegatorGlassButtonStyle {
    static var delegatorGlass: DelegatorGlassButtonStyle { DelegatorGlassButtonStyle() }
}

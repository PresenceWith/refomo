//
//  BreathingCircleView.swift
//  refomo
//
//  Animated breathing circle for meditation overlay

import SwiftUI

struct BreathingCircleView: View {
    let phase: BreathPhase
    let phaseProgress: Double  // 0.0 to 1.0 within current 4-second phase

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var baseSize: CGFloat = 120

    private var scale: CGFloat {
        guard !reduceMotion else { return 1.2 }

        switch phase {
        case .inhale:
            // Expand from 1.0 to 1.4
            return 1.0 + (0.4 * phaseProgress)
        case .holdIn:
            // Stay at 1.4
            return 1.4
        case .exhale:
            // Contract from 1.4 to 1.0
            return 1.4 - (0.4 * phaseProgress)
        case .holdOut:
            // Stay at 1.0
            return 1.0
        }
    }

    private var opacity: Double {
        if reduceMotion {
            // Use opacity instead of scale for reduce motion
            switch phase {
            case .inhale, .holdIn: return 0.9
            case .exhale, .holdOut: return 0.5
            }
        }
        return 0.7
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.meditationAccent.opacity(0.15))
                .frame(width: baseSize * 1.8, height: baseSize * 1.8)
                .scaleEffect(scale)

            // Main breathing circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.meditationAccent.opacity(opacity + 0.2),
                            Color.meditationAccent.opacity(opacity)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: baseSize / 2
                    )
                )
                .frame(width: baseSize, height: baseSize)
                .scaleEffect(scale)

            // Inner highlight
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: baseSize * 0.3, height: baseSize * 0.3)
                .offset(x: -baseSize * 0.15, y: -baseSize * 0.15)
                .scaleEffect(scale)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.1),
            value: scale
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("호흡 가이드")
        .accessibilityValue(phase.instruction)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.85)
        VStack(spacing: 40) {
            BreathingCircleView(phase: .inhale, phaseProgress: 0.5)
            Text("들이쉬세요")
                .foregroundStyle(.white)
        }
    }
}

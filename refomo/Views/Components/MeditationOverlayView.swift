//
//  MeditationOverlayView.swift
//  refomo
//
//  Full-screen meditation overlay with breathing animation

import SwiftUI

struct MeditationOverlayView: View {
    @ObservedObject var viewModel: PomodoroViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .title) private var phaseTextSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var timerTextSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var skipButtonHeight: CGFloat = 44

    /// Progress within current 4-second breath phase (0.0 to 1.0)
    private var phaseProgress: Double {
        // breathPhaseSecondsRemaining counts down from 4 to 1
        // Convert to progress: 4->0.0, 3->0.25, 2->0.5, 1->0.75, 0->1.0
        return 1.0 - (Double(viewModel.breathPhaseSecondsRemaining) / 4.0)
    }

    private var formattedTime: String {
        let minutes = viewModel.meditationRemainingSeconds / 60
        let seconds = viewModel.meditationRemainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture { }  // Prevent tap-through

            VStack(spacing: Spacing.xxl) {
                Spacer()

                // Breath phase instruction
                Text(viewModel.currentBreathPhase.instruction)
                    .font(.system(size: phaseTextSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.currentBreathPhase)
                    .accessibilityAddTraits(.updatesFrequently)

                // Breathing circle
                BreathingCircleView(
                    phase: viewModel.currentBreathPhase,
                    phaseProgress: phaseProgress
                )
                .frame(height: 200)

                // Countdown timer
                Text(formattedTime)
                    .font(.system(size: timerTextSize, weight: .light, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                    .accessibilityLabel("남은 시간 \(viewModel.meditationRemainingSeconds)초")

                Spacer()

                // Skip button
                Button(action: viewModel.skipMeditation) {
                    Text("건너뛰기")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(height: skipButtonHeight)
                        .padding(.horizontal, Spacing.lg)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .accessibilityHint("명상을 조기 종료합니다")
                .padding(.bottom, Spacing.xxl)
            }
        }
        .transition(.opacity)
    }
}

#Preview {
    MeditationOverlayView(viewModel: {
        let vm = PomodoroViewModel()
        vm.isMeditating = true
        vm.meditationRemainingSeconds = 48
        return vm
    }())
}

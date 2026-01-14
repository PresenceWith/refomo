//
//  TimerCircleView.swift
//  refomo
//

import SwiftUI

struct TimerCircleView: View {
    let progress: Double
    let overProgress: Double
    let timerState: TimerState

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - 20

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: radius * 2, height: radius * 2)

                // Progress/overtime pie
                if timerState == .completed {
                    if overProgress > 0 {
                        PieShape(progress: overProgress)
                            .fill(Color.red.opacity(0.3))
                            .frame(width: radius * 2, height: radius * 2)
                    }
                } else if progress > 0 {
                    PieShape(progress: progress)
                        .fill(Color.pomodoroAccent.opacity(0.3))
                        .frame(width: radius * 2, height: radius * 2)
                }

                // Tick marks
                ForEach(0..<60, id: \.self) { i in
                    let is5Min = i % 5 == 0
                    let tickLen: CGFloat = is5Min ? 14 : 8
                    Rectangle()
                        .fill(tickColor(for: i))
                        .frame(width: is5Min ? 2 : 1, height: tickLen)
                        .offset(y: -radius + tickLen / 2 + 4)
                        .rotationEffect(.degrees(Double(i) * 6))
                }
            }
            .frame(width: size, height: size)
            .position(x: size / 2, y: size / 2)
        }
    }

    private func tickColor(for i: Int) -> Color {
        let angle = Double(i) / 60.0
        switch timerState {
        case .idle, .running, .paused:
            return angle < progress ? .pomodoroAccent : Color.gray.opacity(0.3)
        case .completed:
            return angle < overProgress ? Color.red.opacity(0.6) : Color.gray.opacity(0.3)
        }
    }
}

struct PieShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * progress), clockwise: false)
        path.closeSubpath()
        return path
    }
}

// Color.pomodoroAccent is defined in DesignSystem.swift with dark mode support

#Preview {
    TimerCircleView(progress: 0.4, overProgress: 0, timerState: .idle)
        .frame(width: 300, height: 300)
}

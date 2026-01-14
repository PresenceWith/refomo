//
//  PomodoroViewModel.swift
//  refomo
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

enum TimerState { case idle, running, paused, completed }

struct PendingRecord {
    let startTime: Date
    let plannedDuration: Int
    let actualDuration: Int
    let goal: String?
}

@MainActor
final class PomodoroViewModel: ObservableObject {
    @Published var selectedMinutes = 25
    @Published var remainingSeconds = 0
    @Published var overSeconds = 0
    @Published var timerState: TimerState = .idle
    @Published var showRecordView = false
    @Published var goalText = ""

    private var timer: Timer?
    private var startTime: Date?
    private var plannedDuration = 0

    var progress: Double {
        switch timerState {
        case .idle:              return Double(selectedMinutes) / 60.0
        case .running, .paused:  return Double(remainingSeconds) / 3600.0
        case .completed:         return 0
        }
    }

    var overProgress: Double {
        timerState == .completed ? min(Double(overSeconds) / 3600.0, 1.0) : 0
    }

    var displayTime: String {
        switch timerState {
        case .idle:
            return String(format: "%02d:00", selectedMinutes)
        case .running, .paused:
            return String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
        case .completed:
            return String(format: "+%02d:%02d", overSeconds / 60, overSeconds % 60)
        }
    }

    func updateSelectedMinutes(from angle: Double) {
        guard timerState == .idle else { return }
        let normalized = angle < 0 ? angle + 360 : angle
        let minutes = max(1, min(60, Int(round(normalized / 6.0))))
        guard minutes != selectedMinutes else { return }
        selectedMinutes = minutes
        SoundService.shared.playSelectionHaptic()
    }

    func toggleTimer() {
        switch timerState {
        case .idle:    startTimer()
        case .running: pauseTimer()
        case .paused:  resumeTimer()
        case .completed: break
        }
    }

    func startTimer() {
        guard timerState == .idle else { return }
        startTime = Date()
        plannedDuration = selectedMinutes * 60
        remainingSeconds = plannedDuration
        timerState = .running
        setScreenAwake(true)
        SoundService.shared.playHaptic(.light)
        startInternalTimer()
    }

    func resetTimer() {
        stopTimer()
        timerState = .idle
        remainingSeconds = 0
        overSeconds = 0
        startTime = nil
        goalText = ""
    }

    func completeSession() {
        stopTimer()
        showRecordView = true
    }

    func createPendingRecord() -> PendingRecord? {
        guard let startTime else { return nil }
        return PendingRecord(startTime: startTime, plannedDuration: plannedDuration,
                             actualDuration: plannedDuration + overSeconds,
                             goal: goalText.isEmpty ? nil : goalText)
    }

    func finishSession() {
        showRecordView = false
        resetTimer()
    }

    // MARK: - Private

    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        timerState = .paused
        setScreenAwake(false)
        SoundService.shared.playHaptic(.light)
    }

    private func resumeTimer() {
        timerState = .running
        setScreenAwake(true)
        SoundService.shared.playHaptic(.light)
        startInternalTimer()
    }

    private func startInternalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        setScreenAwake(false)
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                timerState = .completed
                SoundService.shared.playCompletionSound()
                SoundService.shared.playHaptic(.heavy)
            }
        } else {
            overSeconds += 1
        }
    }

    private func setScreenAwake(_ awake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = awake
    }
}

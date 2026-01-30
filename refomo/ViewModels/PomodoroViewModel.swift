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

enum BreathPhase {
    case inhale
    case holdIn
    case exhale
    case holdOut

    var instruction: String {
        switch self {
        case .inhale: return "들이쉬세요"
        case .holdIn, .holdOut: return "멈추세요"
        case .exhale: return "내쉬세요"
        }
    }

    var next: BreathPhase {
        switch self {
        case .inhale: return .holdIn
        case .holdIn: return .exhale
        case .exhale: return .holdOut
        case .holdOut: return .inhale
        }
    }

    /// Target scale for breathing circle animation
    var targetScale: CGFloat {
        switch self {
        case .inhale, .holdIn: return 1.4
        case .exhale, .holdOut: return 1.0
        }
    }
}

struct PendingRecord {
    let startTime: Date
    let plannedDuration: Int
    let actualDuration: Int
    let goal: String?
    let meditationCount: Int?
    let meditationSeconds: Int?
}

@MainActor
final class PomodoroViewModel: ObservableObject {
    @Published var selectedMinutes = 25
    @Published var remainingSeconds = 0
    @Published var overSeconds = 0
    @Published var timerState: TimerState = .idle
    @Published var showRecordView = false
    @Published var goalText = ""
    @Published var inProgressMemo = ""
    @Published var showMemoPanel = false
    @Published var isOvertimePaused = false

    // Meditation state
    @Published var isMeditating = false
    @Published var meditationRemainingSeconds = 64  // 4 cycles of 16 seconds each
    @Published var currentBreathPhase: BreathPhase = .inhale
    @Published var breathPhaseSecondsRemaining = 4  // 4 seconds per phase

    private var timer: Timer?
    private var startTime: Date?
    private var plannedDuration = 0
    private(set) var currentRecordId: UUID?

    // Meditation tracking
    private var preMeditationState: TimerState = .idle
    private var meditationTimer: Timer?
    private var currentMeditationCount = 0
    private var currentMeditationSeconds = 0

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
        case .idle:      startTimer()
        case .running:   pauseTimer()
        case .paused:    resumeTimer()
        case .completed: isOvertimePaused ? resumeOvertime() : pauseOvertime()
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
        // Stop meditation if active
        if isMeditating {
            meditationTimer?.invalidate()
            meditationTimer = nil
            isMeditating = false
        }

        stopTimer()
        timerState = .idle
        remainingSeconds = 0
        overSeconds = 0
        startTime = nil
        goalText = ""
        inProgressMemo = ""
        currentRecordId = nil
        isOvertimePaused = false

        // Reset meditation tracking
        currentMeditationCount = 0
        currentMeditationSeconds = 0
    }

    func completeSession() {
        if let recordId = currentRecordId {
            updateActualDuration(recordId: recordId)
        }
        stopTimer()
        showRecordView = true
    }

    func createPendingRecord() -> PendingRecord? {
        guard let startTime else { return nil }
        return PendingRecord(
            startTime: startTime,
            plannedDuration: plannedDuration,
            actualDuration: plannedDuration + overSeconds,
            goal: goalText.isEmpty ? nil : goalText,
            meditationCount: currentMeditationCount > 0 ? currentMeditationCount : nil,
            meditationSeconds: currentMeditationSeconds > 0 ? currentMeditationSeconds : nil
        )
    }

    // MARK: - Meditation

    func startMeditation() {
        guard timerState == .running || timerState == .paused else { return }
        preMeditationState = timerState

        // Pause pomodoro timer if running
        if timerState == .running {
            timer?.invalidate()
            timer = nil
        }

        // Initialize meditation state
        isMeditating = true
        meditationRemainingSeconds = 64
        currentBreathPhase = .inhale
        breathPhaseSecondsRemaining = 4
        currentMeditationCount += 1

        SoundService.shared.playHaptic(.light)
        startMeditationTimer()
    }

    func skipMeditation() {
        endMeditation(completed: false)
    }

    private func endMeditation(completed: Bool) {
        meditationTimer?.invalidate()
        meditationTimer = nil

        // Track meditation time
        let meditatedSeconds = 64 - meditationRemainingSeconds
        currentMeditationSeconds += meditatedSeconds

        isMeditating = false

        // Restore previous timer state
        if preMeditationState == .running {
            timerState = .running
            setScreenAwake(true)
            startInternalTimer()
        }

        SoundService.shared.playHaptic(.medium)
    }

    private func startMeditationTimer() {
        meditationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.meditationTick() }
        }
    }

    private func meditationTick() {
        guard meditationRemainingSeconds > 0 else {
            endMeditation(completed: true)
            return
        }

        meditationRemainingSeconds -= 1
        breathPhaseSecondsRemaining -= 1

        // Transition to next breath phase every 4 seconds
        if breathPhaseSecondsRemaining <= 0 {
            currentBreathPhase = currentBreathPhase.next
            breathPhaseSecondsRemaining = 4
            SoundService.shared.playBreathTransitionHaptic()
        }
    }

    func finishSession() {
        showRecordView = false
        currentRecordId = nil
        resetTimer()
    }

    func saveMemoRecord() {
        guard !inProgressMemo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        if let recordId = currentRecordId {
            updateMemoInRecord(recordId: recordId, memo: inProgressMemo)
        } else {
            let newRecord = createPartialRecord()
            StorageService.shared.append(record: newRecord)
            currentRecordId = newRecord.id
        }
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

    private func pauseOvertime() {
        timer?.invalidate()
        timer = nil
        isOvertimePaused = true
        setScreenAwake(false)
        SoundService.shared.playHaptic(.light)
    }

    private func resumeOvertime() {
        isOvertimePaused = false
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

    private func createPartialRecord() -> PomodoroRecord {
        return PomodoroRecord(
            startTime: startTime ?? Date(),
            plannedDuration: plannedDuration,
            actualDuration: nil,
            goal: goalText.isEmpty ? nil : goalText,
            focusLevel: nil,
            reflection: nil,
            memo: inProgressMemo.isEmpty ? nil : inProgressMemo,
            meditationCount: currentMeditationCount > 0 ? currentMeditationCount : nil,
            meditationSeconds: currentMeditationSeconds > 0 ? currentMeditationSeconds : nil
        )
    }

    private func updateMemoInRecord(recordId: UUID, memo: String) {
        var records = StorageService.shared.load()
        if let index = records.firstIndex(where: { $0.id == recordId }) {
            records[index].memo = memo.isEmpty ? nil : memo
            StorageService.shared.save(records: records)
        }
    }

    private func updateActualDuration(recordId: UUID) {
        var records = StorageService.shared.load()
        if let index = records.firstIndex(where: { $0.id == recordId }) {
            records[index].actualDuration = plannedDuration + overSeconds
            StorageService.shared.save(records: records)
        }
    }
}

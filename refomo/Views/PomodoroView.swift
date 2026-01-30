//
//  PomodoroView.swift
//  refomo
//

import SwiftUI
import UIKit

struct PomodoroView: View {
    @StateObject private var viewModel = PomodoroViewModel()
    @StateObject private var recordViewModel = RecordViewModel()
    @State private var showTime = true
    @FocusState private var isGoalFieldFocused: Bool
    @FocusState private var isTimeFocused: Bool
    @State private var timeInputBuffer: String = ""
    @State private var horizontalOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0

    // Dynamic Type support
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 32

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Accessibility
    private var accessibilityTimerLabel: String {
        switch viewModel.timerState {
        case .idle:
            return "타이머, \(viewModel.selectedMinutes)분으로 설정됨"
        case .running:
            let mins = viewModel.remainingSeconds / 60
            let secs = viewModel.remainingSeconds % 60
            return "타이머 실행 중, \(mins)분 \(secs)초 남음"
        case .paused:
            let mins = viewModel.remainingSeconds / 60
            return "타이머 일시정지됨, \(mins)분 남음"
        case .completed:
            let overMins = viewModel.overSeconds / 60
            let overSecs = viewModel.overSeconds % 60
            return "타이머 완료, 초과 시간 \(overMins)분 \(overSecs)초"
        }
    }

    private var accessibilityTimerHint: String {
        switch viewModel.timerState {
        case .idle:
            return "탭하여 타이머 시작, 길게 눌러 초기화"
        case .running:
            return "탭하여 일시정지, 길게 눌러 초기화"
        case .paused:
            return "탭하여 재개, 길게 눌러 초기화"
        case .completed:
            return viewModel.isOvertimePaused
                ? "탭하여 초과 시간 재개, 길게 눌러 초기화"
                : "탭하여 초과 시간 일시정지, 길게 눌러 초기화"
        }
    }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var panelWidth: CGFloat {
        isLandscape ? 250 : 300
    }

    var body: some View {
        GeometryReader { geo in
            let circleSize = isLandscape
                ? min(geo.size.width * 0.5, geo.size.height * 0.85)
                : min(geo.size.width, geo.size.height) * 0.8

            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isGoalFieldFocused = false
                        isTimeFocused = false
                        if viewModel.showMemoPanel {
                            closeMemoPanel()
                        } else if viewModel.timerState == .running {
                            showTimeTemporarily()
                        }
                    }

                // Sliding container: main content + panel side by side
                HStack(spacing: 0) {
                    // Main content fills screen width
                    Group {
                        if isLandscape {
                            landscapeLayout(circleSize: circleSize, geo: geo)
                        } else {
                            portraitLayout(circleSize: circleSize)
                        }
                    }
                    .frame(width: geo.size.width)

                    // Panel always rendered, positioned off-screen when closed
                    MemoSidePanel(
                        memo: $viewModel.inProgressMemo,
                        isVisible: $viewModel.showMemoPanel,
                        onClose: closeMemoPanel
                    )
                    .frame(width: panelWidth)
                    .accessibilityHidden(!viewModel.showMemoPanel && dragOffset >= 0)
                }
                .frame(maxHeight: .infinity)
                .offset(x: horizontalOffset + dragOffset)

            }
            .clipped()
            .highPriorityGesture(
                (viewModel.timerState == .running || viewModel.timerState == .completed) ?
                DragGesture(minimumDistance: 10)
                    .updating($dragOffset) { value, state, _ in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            state = value.translation.width
                        }
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 30

                        // Left swipe (negative) opens panel, right swipe (positive) closes panel
                        if value.translation.width < -threshold && !viewModel.showMemoPanel {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)) {
                                horizontalOffset = -panelWidth
                                viewModel.showMemoPanel = true
                            }
                            SoundService.shared.playHaptic(.light)
                        } else if value.translation.width > threshold && viewModel.showMemoPanel {
                            closeMemoPanel()
                        } else {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)) {
                                horizontalOffset = viewModel.showMemoPanel ? -panelWidth : 0
                            }
                        }
                    }
                : nil
            )
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: showTime)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: viewModel.timerState)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isTimeFocused)
            .onChange(of: viewModel.timerState) { old, new in
                if new == .running && (old == .idle || old == .paused) {
                    showTimeTemporarilyOnStart()
                    isTimeFocused = false
                }
                if new == .paused { showTime = true }
            }
            .onChange(of: isTimeFocused) { _, newValue in
                if newValue {
                    timeInputBuffer = ""
                }
            }
            .onChange(of: isLandscape) { _, _ in
                if viewModel.showMemoPanel {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)) {
                        horizontalOffset = -panelWidth
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            fabButtons
                .padding(.trailing, 16)
                .padding(.bottom, 16)
        }
        .overlay {
            if viewModel.isMeditating {
                MeditationOverlayView(viewModel: viewModel)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showRecordView) {
            RecordView(viewModel: recordViewModel, onDismiss: viewModel.finishSession)
        }
    }

    // MARK: - Portrait Layout

    @ViewBuilder
    private func portraitLayout(circleSize: CGFloat) -> some View {
        VStack(spacing: 24) {
            goalDisplay
            Spacer()
            timerCircle(circleSize: circleSize)
            timerText
            completeButton
            Spacer()
        }
    }

    // MARK: - Landscape Layout

    @ViewBuilder
    private func landscapeLayout(circleSize: CGFloat, geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            timerCircle(circleSize: circleSize)
                .frame(width: geo.size.width * 0.55)

            VStack(spacing: 20) {
                goalDisplay
                Spacer()
                timerText
                completeButton
                Spacer()
            }
            .frame(width: geo.size.width * 0.45)
        }
        .padding(.horizontal, Spacing.lg)
    }

    // MARK: - Shared Components

    @ViewBuilder
    private func timerCircle(circleSize: CGFloat) -> some View {
        ZStack {
            TimerCircleView(progress: viewModel.progress,
                            overProgress: viewModel.overProgress,
                            timerState: viewModel.timerState)

            if viewModel.timerState == .idle {
                DragHandle(selectedMinutes: viewModel.selectedMinutes,
                           circleSize: circleSize,
                           onAngleChanged: viewModel.updateSelectedMinutes)
            }
        }
        .frame(width: circleSize, height: circleSize)
        .contentShape(Circle())
        .onTapGesture { viewModel.toggleTimer() }
        .onLongPressGesture {
            if viewModel.timerState != .idle {
                viewModel.resetTimer()
                SoundService.shared.playHaptic(.medium)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTimerLabel)
        .accessibilityHint(accessibilityTimerHint)
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    private var showFAB: Bool {
        (viewModel.timerState == .running || viewModel.timerState == .paused || viewModel.timerState == .completed)
            && !viewModel.showMemoPanel
            && !viewModel.isMeditating
    }

    @ViewBuilder
    private var fabButtons: some View {
        if showFAB {
            VStack(spacing: 12) {
                // Meditation FAB
                if viewModel.timerState == .running || viewModel.timerState == .paused || viewModel.timerState == .completed {
                    Button {
                        viewModel.startMeditation()
                    } label: {
                        Image(systemName: "leaf.fill")
                            .font(.title2)
                            .padding()
                            .background(Color.meditationAccent)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .accessibilityLabel("1분 명상")
                    .accessibilityHint("집중이 흐트러질 때 1분간 호흡 명상을 합니다")
                }

                // Memo FAB
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)) {
                        viewModel.showMemoPanel = true
                        horizontalOffset = -panelWidth
                    }
                } label: {
                    Image(systemName: "pencil")
                        .font(.title2)
                        .padding()
                        .background(Color.pomodoroAccent)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .accessibilityLabel("메모 작성")
            }
        }
    }

    @ViewBuilder
    private var timerText: some View {
        Text(viewModel.displayTime)
            .font(.system(size: timerFontSize, weight: .light, design: .monospaced))
            .foregroundColor(timerTextColor)
            .opacity(viewModel.timerState != .running || showTime ? 1 : 0)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.medium)
                    .stroke(isTimeFocused && viewModel.timerState == .idle ? Color.pomodoroAccent : Color.clear, lineWidth: 2)
            )
            .focusable(viewModel.timerState == .idle)
            .focused($isTimeFocused)
            .onKeyPress { key in
                handleTimeKeyPress(key)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.timerState == .idle {
                    isTimeFocused = true
                    timeInputBuffer = ""
                }
            }
            .accessibilityHidden(true)
    }

    private var timerTextColor: Color {
        if isTimeFocused && viewModel.timerState == .idle {
            return Color.pomodoroAccent
        } else if viewModel.timerState == .paused || (viewModel.timerState == .completed && viewModel.isOvertimePaused) {
            return .secondary
        } else {
            return .primary
        }
    }

    private func handleTimeKeyPress(_ key: KeyPress) -> KeyPress.Result {
        guard viewModel.timerState == .idle else { return .ignored }

        // Handle Shift+Tab to go back to goal TextField
        if key.key == .tab && key.modifiers.contains(.shift) {
            isTimeFocused = false
            isGoalFieldFocused = true
            return .handled
        }

        switch key.key {
        case .upArrow:
            let newMinutes = min(60, viewModel.selectedMinutes + 1)
            viewModel.selectedMinutes = newMinutes
            SoundService.shared.playSelectionHaptic()
            return .handled

        case .downArrow:
            let newMinutes = max(1, viewModel.selectedMinutes - 1)
            viewModel.selectedMinutes = newMinutes
            SoundService.shared.playSelectionHaptic()
            return .handled

        case .return:
            isTimeFocused = false
            viewModel.startTimer()
            return .handled

        case .escape:
            isTimeFocused = false
            return .handled

        default:
            // Handle numeric input
            if let char = key.characters.first, char.isNumber {
                // If buffer already has 2 digits, start fresh with new digit
                if timeInputBuffer.count >= 2 {
                    timeInputBuffer = String(char)
                } else {
                    timeInputBuffer.append(char)
                }
                if let minutes = Int(timeInputBuffer) {
                    let clampedMinutes = min(60, max(1, minutes))
                    viewModel.selectedMinutes = clampedMinutes
                    if minutes > 60 {
                        timeInputBuffer = "60"
                    }
                    SoundService.shared.playSelectionHaptic()
                }
                return .handled
            }
            return .ignored
        }
    }

    private var shouldShowGoal: Bool {
        switch viewModel.timerState {
        case .idle:
            return true
        case .running, .paused:
            return !viewModel.goalText.isEmpty
        case .completed:
            return !viewModel.goalText.isEmpty
        }
    }

    @ViewBuilder
    private var goalDisplay: some View {
        ZStack {
            TextField("이번 세션의 목표", text: $viewModel.goalText)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(height: 44)
                .background(
                    viewModel.timerState == .idle
                        ? Color(.secondarySystemBackground)
                        : Color.clear
                )
                .cornerRadius(CornerRadius.medium)
                .foregroundStyle(
                    viewModel.timerState == .paused ? Color.secondary : Color.primary
                )
                .focused($isGoalFieldFocused)
                .onKeyPress(.tab) {
                    isGoalFieldFocused = false
                    isTimeFocused = true
                    timeInputBuffer = ""
                    return .handled
                }
                .onKeyPress(.return) {
                    isGoalFieldFocused = false
                    isTimeFocused = true
                    timeInputBuffer = ""
                    return .handled
                }
                .accessibilityLabel("목표 입력")
                .accessibilityHint("이번 포모도로 세션에서 달성하고 싶은 목표를 입력하세요")
        }
        .frame(height: 44)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
        .opacity(shouldShowGoal ? 1 : 0)
    }

    @ViewBuilder
    private var completeButton: some View {
        if viewModel.timerState == .completed {
            Button {
                // Set up RecordViewModel with existing record if available
                if let recordId = viewModel.currentRecordId {
                    recordViewModel.existingRecordId = recordId
                    if let existingRecord = StorageService.shared.load().first(where: { $0.id == recordId }) {
                        recordViewModel.memo = existingRecord.memo ?? ""
                    }
                }
                recordViewModel.pendingRecord = viewModel.createPendingRecord()
                viewModel.completeSession()
            } label: {
                Text("완료")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 44)
                    .background(Color.pomodoroAccent)
                    .cornerRadius(22)
            }
            .keyboardShortcut(.defaultAction)
            .accessibilityLabel("세션 완료")
            .accessibilityHint("탭하여 이 포모도로 세션을 기록합니다")
        }
    }

    private func showTimeTemporarily() {
        showTime = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.8)) {
                showTime = false
            }
        }
    }

    private func showTimeTemporarilyOnStart() {
        showTime = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if viewModel.timerState == .running {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.8)) {
                    showTime = false
                }
            }
        }
    }

    private func closeMemoPanel() {
        // Dismiss keyboard first
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        viewModel.saveMemoRecord()
        withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)) {
            horizontalOffset = 0
            viewModel.showMemoPanel = false
        }
        SoundService.shared.playHaptic(.medium)
    }
}

struct DragHandle: View {
    let selectedMinutes: Int
    let circleSize: CGFloat
    let onAngleChanged: (Double) -> Void

    @State private var isDragging = false
    @State private var lastHapticMinute: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var angle: Double { Double(selectedMinutes) * 6.0 - 90 }

    private var position: CGPoint {
        let r = circleSize / 2 - 20
        let rad = CGFloat(angle) * .pi / 180
        return CGPoint(x: circleSize / 2 + r * cos(rad), y: circleSize / 2 + r * sin(rad))
    }

    var body: some View {
        Circle()
            .fill(Color.pomodoroAccent)
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
            .scaleEffect(isDragging ? 1.2 : 1.0)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { v in
                        isDragging = true
                        let center = CGPoint(x: circleSize / 2, y: circleSize / 2)
                        let a = atan2(v.location.y - center.y, v.location.x - center.x) * 180 / .pi + 90
                        onAngleChanged(a)

                        // Haptic feedback every 5 minutes
                        if selectedMinutes != lastHapticMinute && selectedMinutes % 5 == 0 {
                            SoundService.shared.playSelectionHaptic()
                            lastHapticMinute = selectedMinutes
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        lastHapticMinute = 0
                    }
            )
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: isDragging)
            .accessibilityLabel("시간 조절 핸들, \(selectedMinutes)분")
            .accessibilityHint("드래그하여 1분에서 60분 사이로 타이머 시간 설정")
            .accessibilityAddTraits(.allowsDirectInteraction)
    }
}

#Preview { PomodoroView() }

//
//  RecordView.swift
//  refomo
//

import SwiftUI

enum RecordField: Hashable { case goal, focusLevel, reflection, memo, saveButton, skipButton }

struct RecordView: View {
    @ObservedObject var viewModel: RecordViewModel
    let onDismiss: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var focusedField: RecordField?

    // Dynamic Type support
    @ScaledMetric(relativeTo: .title2) private var focusButtonSize: CGFloat = 50
    @ScaledMetric(relativeTo: .headline) private var saveButtonHeight: CGFloat = 50

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if isLandscape {
                    landscapeContent
                } else {
                    portraitContent
                }
            }
            .onChange(of: focusedField) { _, f in
                if let f {
                    if reduceMotion {
                        proxy.scrollTo(f, anchor: .center)
                    } else {
                        withAnimation { proxy.scrollTo(f, anchor: .center) }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture { focusedField = .goal }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button(action: movePrev) { Image(systemName: "chevron.up") }
                Button(action: moveNext) { Image(systemName: "chevron.down") }
                Spacer()
                Button("완료") { focusedField = .goal }
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.focusLevel)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if focusedField == nil { focusedField = .goal }
            }
        }
    }

    // MARK: - Portrait Layout

    @ViewBuilder
    private var portraitContent: some View {
        VStack(spacing: Spacing.xxl) {
            VStack(spacing: 8) {
                if !viewModel.sessionInfo.isEmpty {
                    Text(viewModel.sessionInfo)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.top, 24)
                }
            }
            goalSection
            focusLevelSection
            reflectionSection
            memoSection
            Spacer(minLength: 40)
            buttonsSection
        }
        .padding(Spacing.xl)
    }

    // MARK: - Landscape Layout

    @ViewBuilder
    private var landscapeContent: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: 4) {
                if !viewModel.sessionInfo.isEmpty {
                    Text(viewModel.sessionInfo)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }
            }

            HStack(alignment: .top, spacing: Spacing.xl) {
                // Left column: Goal + Focus level + Buttons
                VStack(spacing: Spacing.lg) {
                    goalSection
                    focusLevelSection
                    Spacer(minLength: 20)
                    buttonsSection
                }
                .frame(maxWidth: .infinity)

                // Right column: Reflection + Memo
                VStack(spacing: Spacing.lg) {
                    reflectionSection
                    memoSection
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, Spacing.lg)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
    }

    // MARK: - Sections

    @FocusState private var isGoalFieldFocused: Bool

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("목표").font(.headline)
            TextField("이번 세션의 목표", text: $viewModel.goalText)
                .font(.body)
                .padding(12)
                .background(Color.inputBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pomodoroAccent, lineWidth: focusedField == .goal ? 2 : 0))
                .animateIfAllowed(focusedField == .goal)
                .focused($isGoalFieldFocused)
                .onChange(of: focusedField) { _, newValue in
                    isGoalFieldFocused = newValue == .goal
                }
                .onChange(of: isGoalFieldFocused) { _, focused in
                    if focused { focusedField = .goal }
                }
                .accessibilityLabel("목표")
                .accessibilityHint("이번 세션의 목표를 입력합니다")
        }
        .id(RecordField.goal)
    }

    private var focusLevelSection: some View {
        ZStack {
            KeyboardResponderView(isFocused: focusedField == .focusLevel,
                                  onFocusChange: { if $0 { focusedField = .focusLevel } },
                                  onLeftArrow: { if viewModel.focusLevel > 1 { viewModel.focusLevel -= 1; SoundService.shared.playSelectionHaptic() } },
                                  onRightArrow: { if viewModel.focusLevel < 5 { viewModel.focusLevel += 1; SoundService.shared.playSelectionHaptic() } },
                                  onTab: { focusedField = .reflection },
                                  onShiftTab: { focusedField = .goal })
                .frame(width: 1, height: 1).allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 12) {
                Text("집중도").font(.headline)
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { viewModel.focusLevel = level }
                            SoundService.shared.playSelectionHaptic()
                        } label: {
                            Text("\(level)")
                                .font(.title2).fontWeight(.medium)
                                .frame(width: focusButtonSize, height: focusButtonSize)
                                .background(viewModel.focusLevel == level ? Color.pomodoroAccent : Color.cardBackground)
                                .foregroundColor(viewModel.focusLevel == level ? .white : .primary)
                                .cornerRadius(12)
                                .scaleEffect(viewModel.focusLevel == level ? 1.05 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("집중도 \(level)점")
                        .accessibilityAddTraits(viewModel.focusLevel == level ? .isSelected : [])
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.pomodoroAccent, lineWidth: focusedField == .focusLevel ? 2 : 0))
            .animateIfAllowed( focusedField == .focusLevel)
        }
        .id(RecordField.focusLevel)
    }

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("회고").font(.headline)
            TabNavigableTextEditor(text: $viewModel.reflection,
                                   isFocused: focusedField == .reflection,
                                   onFocusChange: { if $0 { focusedField = .reflection } },
                                   onTabPressed: { focusedField = .memo },
                                   onShiftTabPressed: { focusedField = .focusLevel })
                .frame(minHeight: 100).padding(8)
                .background(Color.inputBackground).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pomodoroAccent, lineWidth: focusedField == .reflection ? 2 : 0))
                .animateIfAllowed( focusedField == .reflection)
        }
        .id(RecordField.reflection)
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메모").font(.headline)
            TabNavigableTextEditor(text: $viewModel.memo,
                                   isFocused: focusedField == .memo,
                                   onFocusChange: { if $0 { focusedField = .memo } },
                                   onTabPressed: { focusedField = .saveButton },
                                   onShiftTabPressed: { focusedField = .reflection })
                .frame(minHeight: 100).padding(8)
                .background(Color.inputBackground).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.pomodoroAccent, lineWidth: focusedField == .memo ? 2 : 0))
                .animateIfAllowed( focusedField == .memo)
        }
        .id(RecordField.memo)
    }

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            ZStack {
                KeyboardResponderView(isFocused: focusedField == .saveButton,
                                      onFocusChange: { if $0 { focusedField = .saveButton } },
                                      onTab: { focusedField = .skipButton },
                                      onShiftTab: { focusedField = .memo },
                                      onEnter: save)
                    .frame(width: 1, height: 1).allowsHitTesting(false)

                Button(action: save) {
                    Text("저장")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: saveButtonHeight)
                        .background(Color.pomodoroAccent).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: focusedField == .saveButton ? 3 : 0))
                        .shadow(color: focusedField == .saveButton ? .black.opacity(0.12) : .clear,
                                radius: 8, x: 0, y: 2)
                        .scaleEffect(focusedField == .saveButton ? 1.02 : 1.0)
                }
                .accessibilityLabel("세션 저장")
                .accessibilityHint("집중도 \(viewModel.focusLevel)점으로 이 세션을 저장합니다")
                .animateIfAllowed( focusedField == .saveButton)
            }
            .id(RecordField.saveButton)

            ZStack {
                KeyboardResponderView(isFocused: focusedField == .skipButton,
                                      onFocusChange: { if $0 { focusedField = .skipButton } },
                                      onTab: { focusedField = .goal },
                                      onShiftTab: { focusedField = .saveButton },
                                      onEnter: { viewModel.skip { onDismiss() } })
                    .frame(width: 1, height: 1).allowsHitTesting(false)

                Button { viewModel.skip { onDismiss() } } label: {
                    Text("건너뛰기")
                        .font(.subheadline)
                        .foregroundColor(focusedField == .skipButton ? .primary : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(focusedField == .skipButton ? Color(.secondarySystemBackground) : Color.clear)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.pomodoroAccent, lineWidth: focusedField == .skipButton ? 2 : 0))
                        .scaleEffect(focusedField == .skipButton ? 1.02 : 1.0)
                }
                .accessibilityLabel("건너뛰기")
                .accessibilityHint("기록하지 않고 이 세션을 종료합니다")
                .animateIfAllowed(focusedField == .skipButton)
            }
            .id(RecordField.skipButton)
            .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func save() {
        SoundService.shared.playHaptic(.medium)
        viewModel.saveRecord { onDismiss() }
    }

    private func moveNext() {
        switch focusedField {
        case .goal:        focusedField = .focusLevel
        case .focusLevel:  focusedField = .reflection
        case .reflection:  focusedField = .memo
        case .memo:        focusedField = .saveButton
        case .saveButton:  focusedField = .skipButton
        case .skipButton:  focusedField = .goal
        default:           focusedField = .goal
        }
    }

    private func movePrev() {
        switch focusedField {
        case .skipButton:  focusedField = .saveButton
        case .saveButton:  focusedField = .memo
        case .memo:        focusedField = .reflection
        case .reflection:  focusedField = .focusLevel
        case .focusLevel:  focusedField = .goal
        case .goal:        focusedField = .skipButton
        default: break
        }
    }
}

#Preview { RecordView(viewModel: RecordViewModel()) {} }

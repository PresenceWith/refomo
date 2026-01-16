//
//  HistoryView.swift
//  refomo
//

import SwiftUI

enum DetailField: Hashable { case reflection, memo }

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedRecord: PomodoroRecord?
    @Binding var isDetailSheetPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
        .background(Color(.systemBackground))
        .onAppear { viewModel.loadRecords() }
        .sheet(item: $selectedRecord, onDismiss: {
            // Delay to allow sheet dismissal animation to complete
            // This prevents the swipe gesture from triggering TabView page switch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isDetailSheetPresented = false
            }
        }) { record in
            RecordDetailView(record: record,
                             onSave: { viewModel.updateRecord($0) },
                             onDelete: { viewModel.deleteRecord(record) })
                .id(record.id)
        }
        .onChange(of: selectedRecord) { _, newValue in
            if newValue != nil {
                isDetailSheetPresented = true
            }
        }
    }

    private var headerView: some View {
        Text("기록")
            .font(.title2)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.records.isEmpty {
            emptyView
        } else {
            recordsListView
        }
    }

    private var emptyView: some View {
        VStack {
            Spacer()
            ContentUnavailableView {
                Label("기록 없음", systemImage: "clock.badge.questionmark")
            } description: {
                Text("첫 포모도로 세션을 완료하면\n여기에 기록이 표시됩니다")
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
    }

    private var recordsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.groupedRecords.keys.sorted().reversed(), id: \.self) { date in
                    Section {
                        ForEach(viewModel.groupedRecords[date] ?? []) { record in
                            RecordRowView(record: record)
                                .onTapGesture { selectedRecord = record }
                        }
                    } header: {
                        Text(viewModel.formatDateHeader(date))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct RecordRowView: View {
    let record: PomodoroRecord

    // Cached formatter
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var isIncomplete: Bool {
        record.actualDuration == nil
    }

    var body: some View {
        HStack(spacing: 12) {
            // 시작 시간 (가장 눈에 띄는 요소)
            Text(Self.timeFormatter.string(from: record.startTime))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Spacer()

            // 진행 중 배지
            if isIncomplete {
                Text("진행 중")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(4)
            }

            // 지속 시간
            if let duration = record.actualDuration {
                Text("\(duration / 60)분")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // 평점 (있을 때만 표시)
            if let level = record.focusLevel {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                    Text("\(level)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.pomodoroAccent)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
        .padding(.horizontal, Spacing.lg)
        .opacity(isIncomplete ? 0.7 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("탭하여 상세 보기")
    }

    private var accessibilityLabel: String {
        var label = "\(Self.timeFormatter.string(from: record.startTime))"
        if let duration = record.actualDuration {
            label += ", \(duration / 60)분 세션"
        } else {
            label += ", 진행 중인 세션"
        }
        if let level = record.focusLevel {
            label += ", 집중도 \(level)점"
        }
        return label
    }
}

struct RecordDetailView: View {
    let record: PomodoroRecord
    let onSave: (PomodoroRecord) -> Void
    let onDelete: () -> Void

    @State private var focusLevel: Int
    @State private var reflection: String
    @State private var memo: String
    @State private var showDeleteConfirm = false
    @State private var focusedField: DetailField?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Dynamic Type support
    @ScaledMetric(relativeTo: .title2) private var focusButtonSize: CGFloat = 50
    @ScaledMetric(relativeTo: .headline) private var saveButtonHeight: CGFloat = 50

    // Cached formatters
    private static let dateFormatterCurrentYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM.dd (E) HH:mm"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    private static let dateFormatterOtherYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd (E) HH:mm"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    private func formatDateTime(_ date: Date) -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let recordYear = Calendar.current.component(.year, from: date)
        if currentYear == recordYear {
            return Self.dateFormatterCurrentYear.string(from: date)
        } else {
            return Self.dateFormatterOtherYear.string(from: date)
        }
    }

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    init(record: PomodoroRecord, onSave: @escaping (PomodoroRecord) -> Void, onDelete: @escaping () -> Void) {
        self.record = record
        self.onSave = onSave
        self.onDelete = onDelete
        _focusLevel = State(initialValue: record.focusLevel ?? 3)
        _reflection = State(initialValue: record.reflection ?? "")
        _memo = State(initialValue: record.memo ?? "")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8).padding(.bottom, 4)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            if isLandscape {
                                landscapeContent
                            } else {
                                portraitContent
                            }
                            // 버튼 영역만큼 하단 여백
                            Spacer().frame(height: isLandscape ? 90 : 120)
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
                    .scrollDismissesKeyboard(.interactively)
                    .contentShape(Rectangle())
                    .simultaneousGesture(TapGesture().onEnded { focusedField = nil })
                }
            }

            // Bottom buttons - 하단 고정, 키보드 무시
            VStack(spacing: 0) {
                bottomButtons
            }
            .background(Color(.systemBackground))
            .ignoresSafeArea(.keyboard)
        }
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button { if focusedField == .memo { focusedField = .reflection } } label: {
                    Image(systemName: "chevron.up")
                }.disabled(focusedField == .reflection)
                Button { if focusedField == .reflection { focusedField = .memo } } label: {
                    Image(systemName: "chevron.down")
                }.disabled(focusedField == .memo)
                Spacer()
                Button("완료") { focusedField = nil }
            }
        }
        .alert("세션 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) { onDelete(); dismiss() }
        } message: {
            Text("이 세션 기록을 삭제하시겠습니까?")
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: focusLevel)
    }

    // MARK: - Portrait Layout

    @ViewBuilder
    private var portraitContent: some View {
        VStack(spacing: 24) {
            headerSection
            focusLevelSection
            reflectionSection
            memoSection
        }
        .padding(24)
    }

    // MARK: - Landscape Layout

    @ViewBuilder
    private var landscapeContent: some View {
        VStack(spacing: 16) {
            headerSection

            HStack(alignment: .top, spacing: 24) {
                // Left column: Focus level
                VStack(spacing: 16) {
                    focusLevelSection
                }
                .frame(maxWidth: .infinity)

                // Right column: Reflection + Memo
                VStack(spacing: 16) {
                    reflectionSection
                    memoSection
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Shared Components

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            if let goal = record.goal, !goal.isEmpty {
                Text(goal)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }
            (Text("\(formatDateTime(record.startTime)) | ")
                + Text("\((record.actualDuration ?? 0) / 60)분").fontWeight(.semibold))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, isLandscape ? 0 : 8)
    }

    @ViewBuilder
    private var focusLevelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("집중도").font(.headline)
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { focusLevel = level }
                        SoundService.shared.playSelectionHaptic()
                    } label: {
                        Text("\(level)")
                            .font(.title2).fontWeight(.medium)
                            .frame(width: focusButtonSize, height: focusButtonSize)
                            .background(focusLevel == level ? Color.pomodoroAccent : Color.cardBackground)
                            .foregroundColor(focusLevel == level ? .white : .primary)
                            .cornerRadius(12)
                            .scaleEffect(focusLevel == level ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("집중도 \(level)점")
                    .accessibilityAddTraits(focusLevel == level ? .isSelected : [])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("회고").font(.headline)
            TabNavigableTextEditor(text: $reflection,
                                   isFocused: focusedField == .reflection,
                                   onFocusChange: { if $0 { focusedField = .reflection } },
                                   onTabPressed: { focusedField = .memo },
                                   onShiftTabPressed: { focusedField = nil })
                .frame(minHeight: isLandscape ? 80 : 100)
                .padding(8)
                .background(Color.cardBackground)
                .cornerRadius(12)
        }
        .id(DetailField.reflection)
    }

    @ViewBuilder
    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메모").font(.headline)
            TabNavigableTextEditor(text: $memo,
                                   isFocused: focusedField == .memo,
                                   onFocusChange: { if $0 { focusedField = .memo } },
                                   onTabPressed: { focusedField = nil },
                                   onShiftTabPressed: { focusedField = .reflection })
                .frame(minHeight: isLandscape ? 80 : 100)
                .padding(8)
                .background(Color.cardBackground)
                .cornerRadius(12)
        }
        .id(DetailField.memo)
    }

    @ViewBuilder
    private var bottomButtons: some View {
        HStack(spacing: isLandscape ? 16 : 0) {
            if isLandscape {
                Button { showDeleteConfirm = true } label: {
                    Text("삭제")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: saveButtonHeight)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                }
                .accessibilityLabel("세션 삭제")
                .accessibilityHint("이 세션 기록을 영구적으로 삭제합니다")
            }

            Button {
                onSave(PomodoroRecord(id: record.id, startTime: record.startTime,
                                      plannedDuration: record.plannedDuration,
                                      actualDuration: record.actualDuration,
                                      goal: record.goal,
                                      focusLevel: focusLevel,
                                      reflection: reflection.isEmpty ? nil : reflection,
                                      memo: memo.isEmpty ? nil : memo))
                dismiss()
            } label: {
                Text("저장")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: saveButtonHeight)
                    .background(Color.pomodoroAccent)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, isLandscape ? 16 : 24)

        if !isLandscape {
            Button { showDeleteConfirm = true } label: {
                Text("삭제").font(.subheadline).foregroundColor(.red)
            }
            .accessibilityLabel("세션 삭제")
            .accessibilityHint("이 세션 기록을 영구적으로 삭제합니다")
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }
}

#Preview { HistoryView(isDetailSheetPresented: .constant(false)) }

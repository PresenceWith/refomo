# Memo Panel Feature Specification

## 1. Feature Overview

타이머 실행 중 메모를 작성할 수 있는 슬라이드-인 사이드 패널. 세션을 중단하지 않고 생각을 기록할 수 있습니다.

**관련 파일:**
- `Views/Components/MemoSidePanel.swift`
- `Views/PomodoroView.swift` (제스처 및 패널 호스팅)
- `ViewModels/PomodoroViewModel.swift` (saveMemoRecord)

## 2. User Stories

### US-MEM-001: 메모 패널 열기
**As a** 사용자
**I want to** 타이머 실행 중 메모 패널을 열기
**So that** 세션 중 떠오르는 생각을 기록할 수 있다

**Acceptance Criteria:**
- AC-MEM-001-1: running 또는 completed 상태에서만 패널 열기 가능
- AC-MEM-001-2: 화면 좌측으로 30pt 이상 스와이프하면 패널 열림
- AC-MEM-001-3: FAB 버튼(연필 아이콘) 탭으로도 열기 가능
- AC-MEM-001-4: Spring 애니메이션으로 슬라이드 (response: 0.45, dampingFraction: 0.82)
- AC-MEM-001-5: 열릴 때 Light 햅틱 피드백

---

### US-MEM-002: 메모 작성
**As a** 사용자
**I want to** 메모 패널에서 텍스트를 작성
**So that** 집중 세션 중 생각을 기록할 수 있다

**Acceptance Criteria:**
- AC-MEM-002-1: 패널 열릴 때 TextEditor 자동 포커스 (0.1초 딜레이)
- AC-MEM-002-2: 메모가 비어있으면 플레이스홀더 텍스트 표시
- AC-MEM-002-3: 글자 수 표시 (메모가 비어있지 않을 때만)
- AC-MEM-002-4: 500자 초과 시 글자 수가 빨간색으로 변경

---

### US-MEM-003: 메모 패널 닫기
**As a** 사용자
**I want to** 메모 패널을 닫기
**So that** 타이머 화면으로 돌아갈 수 있다

**Acceptance Criteria:**
- AC-MEM-003-1: 화면 우측으로 30pt 이상 스와이프하면 패널 닫힘
- AC-MEM-003-2: 닫힐 때 키보드 먼저 해제
- AC-MEM-003-3: 닫힐 때 메모 자동 저장
- AC-MEM-003-4: 첫 메모 저장 시 부분 레코드 생성 (actualDuration: nil)
- AC-MEM-003-5: 이후 저장 시 기존 레코드 업데이트
- AC-MEM-003-6: Medium 햅틱 피드백

---

### US-MEM-004: 메모 자동 저장 및 복원
**As a** 사용자
**I want to** 메모가 자동으로 저장되고 복원되길
**So that** 데이터를 잃지 않을 수 있다

**Acceptance Criteria:**
- AC-MEM-004-1: 패널 닫힘 시 자동 저장
- AC-MEM-004-2: 같은 세션 내에서 다시 열면 이전 메모 표시
- AC-MEM-004-3: 타이머 완료 후 RecordView에서 메모 계속 편집 가능
- AC-MEM-004-4: 타이머 리셋 시 메모 초기화

## 3. UI Specifications

### 3.1 Panel Layout
```
┌─────────────────────────────────┐
│     → 스와이프하여 닫기         │ ← Close Hint
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │  타이머 실행 중 메모를       │ │ ← Placeholder (when empty)
│ │  작성할 수 있습니다          │ │
│ │                             │ │
│ │                             │ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                      123 / 500  │ ← Character Count (when not empty)
└─────────────────────────────────┘
```

### 3.2 Panel Container
| Property | Value |
|----------|-------|
| Width (Portrait) | 300pt |
| Width (Landscape) | 250pt |
| Background | tertiarySystemBackground |
| Padding | 16pt (@ScaledMetric) |
| Position | 화면 우측에서 슬라이드 인 |

### 3.3 Close Hint
| Property | Value |
|----------|-------|
| Text | "→ 스와이프하여 닫기" |
| Font | system(size: 12) (@ScaledMetric) |
| Color | secondary |
| Alignment | center |

### 3.4 Text Editor
| Property | Value |
|----------|-------|
| Background | secondarySystemBackground |
| Corner radius | 10pt |
| Padding | 8pt |
| Placeholder | "타이머 실행 중 메모를 작성할 수 있습니다" |
| Placeholder color | placeholderText |
| Placeholder padding | 4pt horizontal, 8pt vertical |

### 3.5 Character Count
| Property | Value |
|----------|-------|
| Visibility | 메모가 비어있지 않을 때만 |
| Font | caption2 |
| Color (normal) | secondary |
| Color (over 500) | red |
| Alignment | trailing |
| Format | "{count} / 500" |

### 3.6 Keyboard Toolbar
| Element | Action |
|---------|--------|
| "완료" 버튼 | 키보드 해제 (resignFirstResponder) |

## 4. Gestures

### 4.1 스와이프 제스처 (PomodoroView에서 처리)

| Action | Direction | Threshold | Condition | Result |
|--------|-----------|-----------|-----------|--------|
| Open | Left (negative) | -30pt | !showMemoPanel && (running \|\| completed) | 패널 열기 |
| Close | Right (positive) | +30pt | showMemoPanel | 패널 닫기 |

### 4.2 제스처 구현
```swift
DragGesture(minimumDistance: 10)
    .updating($dragOffset) { value, state, _ in
        if abs(value.translation.width) > abs(value.translation.height) {
            state = value.translation.width
        }
    }
    .onEnded { value in
        let threshold: CGFloat = 30

        if value.translation.width < -threshold && !showMemoPanel {
            // Open panel
        } else if value.translation.width > threshold && showMemoPanel {
            // Close panel
        }
    }
```

### 4.3 FAB 버튼
(01-timer.md 3.6 참조)

## 5. Animation

### 5.1 Panel Slide Animation
| Property | Value |
|----------|-------|
| Type | Spring |
| Response | 0.45 |
| Damping Fraction | 0.82 |
| Reduce Motion | 애니메이션 없음 (nil) |

### 5.2 Offset Calculation
```swift
// 패널 열림
horizontalOffset = -panelWidth  // -300pt (portrait) or -250pt (landscape)

// 패널 닫힘
horizontalOffset = 0
```

### 5.3 드래그 미리보기
```swift
// 실시간 드래그 오프셋
.offset(x: horizontalOffset + dragOffset)
```

## 6. Data Flow

### 6.1 메모 저장 흐름
```
User closes panel
    │
    ▼
closeMemoPanel()
    │
    ├── UIApplication.resignFirstResponder() (키보드 해제)
    │
    ├── PomodoroViewModel.saveMemoRecord()
    │   │
    │   ├── [메모가 비어있음]
    │   │   └── return (저장 안 함)
    │   │
    │   ├── [currentRecordId 있음]
    │   │   └── updateMemoInRecord(recordId, memo)
    │   │       └── StorageService.save(records)
    │   │
    │   └── [currentRecordId 없음]
    │       └── createPartialRecord()
    │           ├── PomodoroRecord 생성 (actualDuration: nil)
    │           ├── StorageService.append(record)
    │           └── currentRecordId = newRecord.id
    │
    ├── horizontalOffset = 0 (애니메이션)
    │
    ├── showMemoPanel = false
    │
    └── SoundService.playHaptic(.medium)
```

### 6.2 부분 레코드 구조
```swift
PomodoroRecord(
    startTime: startTime ?? Date(),
    plannedDuration: plannedDuration,
    actualDuration: nil,              // ← 진행 중 표시
    goal: goalText.isEmpty ? nil : goalText,
    focusLevel: nil,
    reflection: nil,
    memo: inProgressMemo.isEmpty ? nil : inProgressMemo
)
```

### 6.3 RecordView로 메모 전달
```swift
// PomodoroView에서 completeSession() 호출 전
if let recordId = viewModel.currentRecordId {
    recordViewModel.existingRecordId = recordId
    if let existingRecord = StorageService.shared.load().first(where: { $0.id == recordId }) {
        recordViewModel.memo = existingRecord.memo ?? ""
    }
}
```

## 7. Accessibility

### 7.1 Panel Container
| Property | Value |
|----------|-------|
| accessibilityElement | children: .contain |
| accessibilityLabel | "메모 패널" |

### 7.2 Panel Hidden State
```swift
// 패널이 닫혀있고 드래그 중이 아닐 때 VoiceOver에서 숨김
.accessibilityHidden(!viewModel.showMemoPanel && dragOffset >= 0)
```

### 7.3 FAB Button
| Property | Value |
|----------|-------|
| accessibilityLabel | "메모 작성" |

## 8. Landscape Adaptation

### 8.1 Size Changes
| Property | Portrait | Landscape |
|----------|----------|-----------|
| Panel width | 300pt | 250pt |

### 8.2 방향 전환 시 오프셋 업데이트
```swift
.onChange(of: isLandscape) { _, _ in
    if viewModel.showMemoPanel {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            horizontalOffset = -panelWidth
        }
    }
}
```

## 9. Edge Cases

### 9.1 빈 메모 저장 시
- 메모가 whitespace만 있거나 비어있으면 저장하지 않음
- `trimmingCharacters(in: .whitespacesAndNewlines)` 후 empty 체크

### 9.2 타이머 리셋 시
- `inProgressMemo = ""` 초기화
- `currentRecordId = nil` 초기화
- 저장된 부분 레코드는 History에 유지 (actualDuration: nil 상태로)

### 9.3 idle 상태에서
- 패널 열기 제스처 무시
- FAB 버튼 숨김

---

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |

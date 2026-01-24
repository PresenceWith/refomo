# Timer Feature Specification

## 1. Feature Overview

메인 포모도로 타이머 화면. 원형 다이얼 인터페이스로 시간을 설정하고 세션을 관리합니다.

**관련 파일:**
- `Views/PomodoroView.swift`
- `ViewModels/PomodoroViewModel.swift`
- `Views/Components/TimerCircleView.swift`

## 2. User Stories

### US-TIM-001: 타이머 시간 설정
**As a** 사용자
**I want to** 1분에서 60분 사이로 타이머 시간을 설정
**So that** 원하는 길이의 집중 세션을 가질 수 있다

**Acceptance Criteria:**
- AC-TIM-001-1: 원형 다이얼의 드래그 핸들을 드래그하여 분 설정
- AC-TIM-001-2: 60개의 틱 마크가 각 분을 표시
- AC-TIM-001-3: 키보드 화살표 키(↑/↓)로 분 조절 가능
- AC-TIM-001-4: 시간 표시 영역 탭 후 숫자 직접 입력 가능 (1-60)
- AC-TIM-001-5: 5분 단위로 드래그 중 햅틱 피드백 제공

---

### US-TIM-002: 타이머 시작
**As a** 사용자
**I want to** 타이머를 시작
**So that** 집중 세션을 시작할 수 있다

**Acceptance Criteria:**
- AC-TIM-002-1: 원형 영역 탭으로 타이머 시작
- AC-TIM-002-2: 시작 시 화면 슬립 방지 활성화
- AC-TIM-002-3: 시작 시 Light 햅틱 피드백
- AC-TIM-002-4: 상태가 idle → running으로 전환
- AC-TIM-002-5: 시간 표시가 MM:SS 형식으로 카운트다운 시작

---

### US-TIM-003: 타이머 일시정지/재개
**As a** 사용자
**I want to** 타이머를 일시정지하고 재개
**So that** 잠시 쉬었다가 이어서 진행할 수 있다

**Acceptance Criteria:**
- AC-TIM-003-1: running 상태에서 원형 영역 탭 → paused
- AC-TIM-003-2: paused 상태에서 원형 영역 탭 → running
- AC-TIM-003-3: 일시정지 시 화면 슬립 방지 해제
- AC-TIM-003-4: 재개 시 화면 슬립 방지 재활성화
- AC-TIM-003-5: Light 햅틱 피드백

---

### US-TIM-004: 타이머 리셋
**As a** 사용자
**I want to** 타이머를 초기화
**So that** 처음부터 다시 시작할 수 있다

**Acceptance Criteria:**
- AC-TIM-004-1: 원형 영역 길게 누르기로 리셋 (idle 상태 제외)
- AC-TIM-004-2: 리셋 시 목표 텍스트와 메모 초기화
- AC-TIM-004-3: 리셋 시 currentRecordId 초기화
- AC-TIM-004-4: Medium 햅틱 피드백
- AC-TIM-004-5: 상태가 idle로 전환

---

### US-TIM-005: 타이머 완료
**As a** 사용자
**I want to** 타이머 완료를 알림받기
**So that** 집중 세션이 끝났음을 알 수 있다

**Acceptance Criteria:**
- AC-TIM-005-1: remainingSeconds가 0이 되면 완료 사운드 재생 (System Sound 1103)
- AC-TIM-005-2: Heavy 햅틱 피드백
- AC-TIM-005-3: 상태가 completed로 전환
- AC-TIM-005-4: 초과 시간 카운트 시작 (+MM:SS 형식 표시)
- AC-TIM-005-5: "완료" 버튼 표시

---

### US-TIM-006: 세션 목표 설정
**As a** 사용자
**I want to** 세션 목표를 입력
**So that** 집중하고자 하는 내용을 기억할 수 있다

**Acceptance Criteria:**
- AC-TIM-006-1: idle 상태에서 목표 입력 필드 표시
- AC-TIM-006-2: running/paused/completed 상태에서는 입력 불가 (읽기 전용)
- AC-TIM-006-3: 목표가 비어있으면 running/paused/completed에서 숨김
- AC-TIM-006-4: 목표가 있으면 모든 상태에서 표시
- AC-TIM-006-5: 목표는 세션 기록에 저장됨

---

### US-TIM-007: 시간 표시 자동 숨김
**As a** 사용자
**I want to** running 상태에서 시간 표시가 자동으로 숨겨지길
**So that** 시간에 집착하지 않고 집중할 수 있다

**Acceptance Criteria:**
- AC-TIM-007-1: running 상태 진입 후 3초 뒤 시간 표시 페이드 아웃
- AC-TIM-007-2: 화면 탭 시 시간 일시적으로 표시 (3초)
- AC-TIM-007-3: paused 상태에서는 항상 표시
- AC-TIM-007-4: Reduce Motion 설정 시 페이드 효과 없음

## 3. UI Specifications

### 3.1 Timer Circle

#### TimerCircleView
| Property | Value |
|----------|-------|
| Size (Portrait) | min(width, height) * 0.8 |
| Size (Landscape) | min(width * 0.5, height * 0.85) |
| Tick marks | 60개 |
| 5분 틱 높이 | 14pt |
| 일반 틱 높이 | 8pt |
| 5분 틱 너비 | 2pt |
| 일반 틱 너비 | 1pt |

#### 색상 상태
| State | 색상 |
|-------|------|
| idle | pomodoroAccent |
| running | pomodoroAccent |
| paused | pomodoroAccent |
| completed (overtime) | red |

### 3.2 Drag Handle
| Property | Value |
|----------|-------|
| Size | 24 x 24pt |
| Color | pomodoroAccent |
| Shadow | subtle (black 8%, radius 4, y: 1) |
| Scale (dragging) | 1.2 |
| Position | 원 둘레에서 20pt 안쪽 |

### 3.3 Timer Display
| Property | Value |
|----------|-------|
| Font | System monospaced |
| Size | 32pt (@ScaledMetric) |
| Weight | Light |
| Color (normal) | primary |
| Color (paused) | secondary |
| Color (focused) | pomodoroAccent |
| Format (running/paused) | MM:SS |
| Format (overtime) | +MM:SS |

### 3.4 Goal Input
| Property | Value |
|----------|-------|
| Height | 44pt |
| Background (idle) | secondarySystemBackground |
| Background (other states) | clear |
| Corner radius | medium (10pt) |
| Font | body |
| Alignment | center |
| Placeholder | "이번 세션의 목표" |

### 3.5 Complete Button
| Property | Value |
|----------|-------|
| Size | 100 x 44pt |
| Background | pomodoroAccent |
| Corner radius | 22pt (pill) |
| Text | "완료" (headline, white) |
| Keyboard shortcut | ⌘+Return (defaultAction) |

### 3.6 FAB (Memo Button)
| Property | Value |
|----------|-------|
| Visibility | running 또는 completed 상태 + 메모 패널 닫힘 |
| Icon | pencil (title2) |
| Background | pomodoroAccent |
| Foreground | white |
| Shape | Circle |
| Shadow | radius 4 |
| Position | 우하단 (Spacing.md 패딩) |

## 4. State Machine

```
                    ┌──────────────┐
                    │     idle     │
                    └──────┬───────┘
                           │ tap circle
                           │ startTimer()
                           ▼
           ┌───────────────────────────────┐
           │           running             │◀───┐
           └───────────────┬───────────────┘    │
                           │                     │
              ┌────────────┼────────────┐       │
              │            │            │       │
              ▼            │            ▼       │
    ┌─────────────┐       │    ┌─────────────┐ │
    │   paused    │───────┼───▶│  completed  │ │
    └─────────────┘       │    └──────┬──────┘ │
              │           │           │        │
              └───────────┘           │        │
                 tap circle           │        │
                 resumeTimer()        │        │
                                      │        │
                           ┌──────────┘        │
                           │ tap "완료"         │
                           │ completeSession() │
                           ▼                   │
                    ┌──────────────┐           │
                    │  RecordView  │           │
                    └──────┬───────┘           │
                           │ save/skip         │
                           │ finishSession()   │
                           ▼                   │
                    ┌──────────────┐           │
                    │     idle     │───────────┘
                    └──────────────┘
                           ▲
                           │ long press
                           │ resetTimer()
                           │
              (from running, paused, completed)
```

### 4.1 TimerState Enum
```swift
enum TimerState {
    case idle       // 초기 상태, 시간 설정 가능
    case running    // 카운트다운 진행 중
    case paused     // 일시정지
    case completed  // 완료, 초과 시간 카운트 중
}
```

## 5. Gestures

| Gesture | State | Element | Action |
|---------|-------|---------|--------|
| Tap | idle | Circle | startTimer() |
| Tap | running | Circle | pauseTimer() |
| Tap | paused | Circle | resumeTimer() |
| Tap | completed | Circle | - (no action) |
| Long press | !idle | Circle | resetTimer() |
| Drag | idle | Handle | updateSelectedMinutes() |
| Left swipe | running/completed | Screen | 메모 패널 열기 |
| Right swipe | - | Screen | 메모 패널 닫기 |
| Tap | running | Screen | 시간 일시 표시 |

### 5.1 Swipe Gesture Details
| Property | Value |
|----------|-------|
| Minimum distance | 10pt |
| Open threshold | -30pt (좌측으로) |
| Close threshold | +30pt (우측으로) |
| Animation | spring(response: 0.45, dampingFraction: 0.82) |

## 6. Keyboard Navigation

### 6.1 Focus Order
1. Goal TextField
2. Timer Display (focusable in idle state)

### 6.2 Key Commands

#### Goal TextField
| Key | Action |
|-----|--------|
| Tab | Timer Display로 이동 |
| Return | Timer Display로 이동 |

#### Timer Display (idle)
| Key | Action |
|-----|--------|
| ↑ | 분 +1 (max 60) |
| ↓ | 분 -1 (min 1) |
| 숫자 | 분 직접 입력 (2자리) |
| Return | 타이머 시작 |
| Escape | 포커스 해제 |
| Shift+Tab | Goal TextField로 이동 |

## 7. Accessibility

### 7.1 Timer Circle
| Property | Value |
|----------|-------|
| accessibilityLabel | 상태에 따른 동적 레이블 (아래 참조) |
| accessibilityHint | 상태에 따른 동적 힌트 (아래 참조) |
| accessibilityTraits | .allowsDirectInteraction |

#### Label by State
| State | Label |
|-------|-------|
| idle | "타이머, {N}분으로 설정됨" |
| running | "타이머 실행 중, {M}분 {S}초 남음" |
| paused | "타이머 일시정지됨, {M}분 남음" |
| completed | "타이머 완료, 초과 시간 {M}분 {S}초" |

#### Hint by State
| State | Hint |
|-------|------|
| idle | "탭하여 타이머 시작, 길게 눌러 초기화" |
| running | "탭하여 일시정지, 길게 눌러 초기화" |
| paused | "탭하여 재개, 길게 눌러 초기화" |
| completed | "완료 버튼을 눌러 기록 저장" |

### 7.2 Drag Handle
| Property | Value |
|----------|-------|
| accessibilityLabel | "시간 조절 핸들, {N}분" |
| accessibilityHint | "드래그하여 1분에서 60분 사이로 타이머 시간 설정" |
| accessibilityTraits | .allowsDirectInteraction |

### 7.3 Goal Input
| Property | Value |
|----------|-------|
| accessibilityLabel | "목표 입력" |
| accessibilityHint | "이번 포모도로 세션에서 달성하고 싶은 목표를 입력하세요" |

### 7.4 Complete Button
| Property | Value |
|----------|-------|
| accessibilityLabel | "세션 완료" |
| accessibilityHint | "탭하여 이 포모도로 세션을 기록합니다" |

### 7.5 FAB Button
| Property | Value |
|----------|-------|
| accessibilityLabel | "메모 작성" |

### 7.6 Timer Display
| Property | Value |
|----------|-------|
| accessibilityHidden | true (Circle label과 중복 방지) |

## 8. Landscape Adaptation

### 8.1 Layout Change
| Orientation | Layout |
|-------------|--------|
| Portrait | VStack: Goal → Circle → Time → Button |
| Landscape | HStack: Circle (55%) + Content (45%) |

### 8.2 Size Adjustments
| Element | Portrait | Landscape |
|---------|----------|-----------|
| Circle size | min(w,h) * 0.8 | min(w*0.5, h*0.85) |
| Panel width | 300pt | 250pt |
| Content spacing | 24pt | 20pt |

---

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |

# Session Record Feature Specification

## 1. Feature Overview

타이머 완료 후 세션 메타데이터(집중도, 회고, 메모)를 입력하는 Full Screen Cover 화면.

**관련 파일:**
- `Views/RecordView.swift`
- `ViewModels/RecordViewModel.swift`
- `Views/Components/TabNavigableTextEditor.swift`

## 2. User Stories

### US-REC-001: 집중도 평가
**As a** 사용자
**I want to** 1-5 사이의 집중도를 평가
**So that** 시간에 따른 집중력 추이를 추적할 수 있다

**Acceptance Criteria:**
- AC-REC-001-1: 5개의 버튼이 수평으로 배치됨 (1, 2, 3, 4, 5)
- AC-REC-001-2: 선택된 버튼은 pomodoroAccent 배경 + 흰색 텍스트 + 1.05 스케일
- AC-REC-001-3: 기본 선택값: 3
- AC-REC-001-4: 선택 변경 시 Selection 햅틱 피드백
- AC-REC-001-5: 좌/우 화살표 키로 선택 변경 가능

---

### US-REC-002: 회고 작성
**As a** 사용자
**I want to** 세션에 대한 회고를 작성
**So that** 인사이트를 기록할 수 있다

**Acceptance Criteria:**
- AC-REC-002-1: 최소 높이 100pt의 TextEditor 제공
- AC-REC-002-2: Tab 키로 메모 필드로 이동
- AC-REC-002-3: Shift+Tab 키로 집중도로 이동
- AC-REC-002-4: 포커스 시 pomodoroAccent 색상의 2pt 테두리 표시

---

### US-REC-003: 메모 작성/수정
**As a** 사용자
**I want to** 메모를 작성하거나 수정
**So that** 추가 메모를 남길 수 있다

**Acceptance Criteria:**
- AC-REC-003-1: 최소 높이 100pt의 TextEditor 제공
- AC-REC-003-2: 진행 중 저장된 메모가 있으면 자동으로 불러옴
- AC-REC-003-3: Tab 키로 저장 버튼으로 이동
- AC-REC-003-4: Shift+Tab 키로 회고 필드로 이동
- AC-REC-003-5: 포커스 시 pomodoroAccent 색상의 2pt 테두리 표시

---

### US-REC-004: 세션 저장
**As a** 사용자
**I want to** 세션 기록을 저장
**So that** History에서 확인할 수 있다

**Acceptance Criteria:**
- AC-REC-004-1: "저장" 버튼 탭으로 저장
- AC-REC-004-2: 진행 중 메모가 있으면 기존 레코드 업데이트 (StorageService.update)
- AC-REC-004-3: 진행 중 메모가 없으면 새 레코드 생성 (StorageService.append)
- AC-REC-004-4: Medium 햅틱 피드백
- AC-REC-004-5: 저장 후 타이머 화면으로 복귀 (idle 상태)
- AC-REC-004-6: 빈 문자열은 nil로 저장

---

### US-REC-005: 기록 건너뛰기
**As a** 사용자
**I want to** 기록을 건너뛰기
**So that** 빠르게 새 세션을 시작할 수 있다

**Acceptance Criteria:**
- AC-REC-005-1: "건너뛰기" 버튼 탭으로 건너뛰기
- AC-REC-005-2: 진행 중 메모가 있으면 해당 레코드는 유지 (actualDuration, 메모만 있는 상태)
- AC-REC-005-3: 진행 중 메모가 없으면 아무 레코드도 생성되지 않음
- AC-REC-005-4: 타이머 화면으로 복귀 (idle 상태)

## 3. UI Specifications

### 3.1 Screen Layout

#### Portrait
```
┌─────────────────────────────────┐
│         [Goal Text]            │ ← 있으면 표시
│            25분                │ ← sessionInfo
├─────────────────────────────────┤
│ 집중도                          │
│ [1] [2] [3] [4] [5]            │
├─────────────────────────────────┤
│ 회고                            │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 메모                            │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ │                             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│                                │
│      [      저장      ]        │
│         건너뛰기                │
└─────────────────────────────────┘
```

#### Landscape
```
┌─────────────────────────────────────────────────────────┐
│                      [Goal Text] 25분                   │
├────────────────────────┬────────────────────────────────┤
│ 집중도                  │ 회고                           │
│ [1] [2] [3] [4] [5]    │ ┌──────────────────────────┐   │
│                        │ │                          │   │
│                        │ └──────────────────────────┘   │
│ [      저장      ]     │ 메모                           │
│    건너뛰기             │ ┌──────────────────────────┐   │
│                        │ │                          │   │
│                        │ └──────────────────────────┘   │
└────────────────────────┴────────────────────────────────┘
```

### 3.2 Header
| Property | Value |
|----------|-------|
| Goal text font | title2, semibold |
| Goal text alignment | center |
| Goal text padding-top | 24pt |
| Session info font | subheadline, bold |
| Session info color | secondary |
| Session info format | "{N}분" |

### 3.3 Focus Level Buttons
| Property | Value |
|----------|-------|
| Button size | 50 x 50pt (@ScaledMetric) |
| Spacing | 12pt |
| Unselected background | cardBackground |
| Unselected text | primary |
| Selected background | pomodoroAccent |
| Selected text | white |
| Selected scale | 1.05 |
| Corner radius | 12pt |
| Font | title2, medium |

### 3.4 Text Editors (Reflection, Memo)
| Property | Value |
|----------|-------|
| Min height (Portrait) | 100pt |
| Min height (Landscape) | 80pt |
| Background | inputBackground (RecordView), cardBackground (RecordDetailView) |
| Corner radius | 12pt |
| Padding | 8pt |
| Focus border | pomodoroAccent, 2pt |

### 3.5 Save Button
| Property | Value |
|----------|-------|
| Height | 50pt (@ScaledMetric) |
| Width | 100% (maxWidth: .infinity) |
| Background | pomodoroAccent |
| Text | "저장" (headline, white) |
| Corner radius | 12pt |
| Focus state border | white 3pt |
| Focus state shadow | card shadow |
| Focus state scale | 1.02 |

### 3.6 Skip Button
| Property | Value |
|----------|-------|
| Font | subheadline |
| Color (normal) | secondary |
| Color (focused) | primary |
| Background (focused) | secondarySystemBackground |
| Corner radius | 8pt |
| Focus border | pomodoroAccent, 2pt |
| Focus scale | 1.02 |

## 4. Keyboard Navigation

### 4.1 Focus Order (Tab Cycle)
```
Focus Level → Reflection → Memo → Save Button → Skip Button → Focus Level
```

### 4.2 Key Commands by Field

#### Focus Level
| Key | Action |
|-----|--------|
| ← | focusLevel - 1 (min 1) |
| → | focusLevel + 1 (max 5) |
| Tab | Reflection으로 이동 |
| Shift+Tab | Skip Button으로 이동 |

#### Reflection / Memo
| Key | Action |
|-----|--------|
| Tab | 다음 필드로 이동 |
| Shift+Tab | 이전 필드로 이동 |

#### Save Button
| Key | Action |
|-----|--------|
| Enter | 저장 실행 |
| Tab | Skip Button으로 이동 |
| Shift+Tab | Memo로 이동 |

#### Skip Button
| Key | Action |
|-----|--------|
| Enter | 건너뛰기 실행 |
| Tab | Focus Level로 이동 |
| Shift+Tab | Save Button으로 이동 |

### 4.3 Keyboard Toolbar
| Element | Action |
|---------|--------|
| ↑ 버튼 | 이전 필드로 이동 |
| ↓ 버튼 | 다음 필드로 이동 |
| "완료" 버튼 | 포커스를 Focus Level로 이동 |

## 5. Accessibility

### 5.1 Focus Level Buttons
| Property | Value |
|----------|-------|
| accessibilityLabel | "집중도 {N}점" |
| accessibilityTraits (selected) | .isSelected |

### 5.2 Save Button
| Property | Value |
|----------|-------|
| accessibilityLabel | "세션 저장" |
| accessibilityHint | "집중도 {N}점으로 이 세션을 저장합니다" |

### 5.3 Skip Button
| Property | Value |
|----------|-------|
| accessibilityLabel | "건너뛰기" |
| accessibilityHint | "기록하지 않고 이 세션을 종료합니다" |

## 6. Data Flow

### 6.1 RecordView 초기화 시
```
PomodoroView.completeSession()
    │
    ├── recordViewModel.existingRecordId = viewModel.currentRecordId
    │   (진행 중 메모가 있는 경우)
    │
    ├── recordViewModel.memo = existingRecord.memo
    │   (기존 메모 불러오기)
    │
    └── recordViewModel.pendingRecord = viewModel.createPendingRecord()
```

### 6.2 저장 시
```
RecordViewModel.saveRecord()
    │
    ├── [existingRecordId 있음]
    │   └── StorageService.update(record)
    │       - focusLevel, reflection, memo 업데이트
    │
    └── [existingRecordId 없음]
        └── StorageService.append(record)
            - 새 PomodoroRecord 생성
```

### 6.3 건너뛰기 시
```
RecordViewModel.skip()
    │
    ├── [existingRecordId 있음]
    │   └── 레코드 유지 (actualDuration + memo만 있는 상태)
    │
    └── [existingRecordId 없음]
        └── 아무것도 저장 안 됨
```

## 7. Landscape Adaptation

### 7.1 Layout Change
| Orientation | Layout |
|-------------|--------|
| Portrait | VStack 단일 컬럼 |
| Landscape | HStack 2컬럼 (좌: Focus+Buttons, 우: Reflection+Memo) |

### 7.2 Size Adjustments
| Element | Portrait | Landscape |
|---------|----------|-----------|
| Text editor min height | 100pt | 80pt |
| Section spacing | 32pt (xxl) | 20pt (lg) |
| Padding | 24pt (xl) | 16pt (md) vertical, 24pt horizontal |

---

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |

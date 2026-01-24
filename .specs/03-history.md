# History Feature Specification

## 1. Feature Overview

과거 포모도로 세션 기록을 조회하고 편집하는 화면. 날짜별로 그룹화된 목록과 상세 편집 시트를 제공합니다.

**관련 파일:**
- `Views/HistoryView.swift` (HistoryView, RecordRowView, RecordDetailView)
- `ViewModels/HistoryViewModel.swift`

## 2. User Stories

### US-HIS-001: 세션 기록 목록 조회
**As a** 사용자
**I want to** 과거 세션 기록을 목록으로 조회
**So that** 내 포모도로 활동을 확인할 수 있다

**Acceptance Criteria:**
- AC-HIS-001-1: 기록이 날짜별로 그룹화되어 표시
- AC-HIS-001-2: 날짜 헤더 형식: "오늘", "어제", 또는 "M월 d일 (E)"
- AC-HIS-001-3: 각 그룹 내에서 최신순 정렬 (같은 날 중 늦은 시간이 위)
- AC-HIS-001-4: 기록이 없으면 Empty State 표시

---

### US-HIS-002: 세션 상세 보기
**As a** 사용자
**I want to** 세션의 상세 정보를 보기
**So that** 해당 세션의 회고와 메모를 확인할 수 있다

**Acceptance Criteria:**
- AC-HIS-002-1: 기록 행 탭으로 상세 시트 열기
- AC-HIS-002-2: 시트에서 목표, 날짜/시간, 길이, 집중도, 회고, 메모 표시
- AC-HIS-002-3: 드래그 핸들(capsule)로 시트 닫기 가능

---

### US-HIS-003: 세션 편집
**As a** 사용자
**I want to** 과거 세션의 집중도, 회고, 메모를 편집
**So that** 나중에 내용을 수정하거나 추가할 수 있다

**Acceptance Criteria:**
- AC-HIS-003-1: 집중도 버튼으로 1-5 변경 가능
- AC-HIS-003-2: 회고 텍스트 편집 가능
- AC-HIS-003-3: 메모 텍스트 편집 가능
- AC-HIS-003-4: 시작 시간과 길이는 편집 불가 (읽기 전용)
- AC-HIS-003-5: "저장" 버튼으로 변경사항 저장
- AC-HIS-003-6: 저장 시 즉시 목록에 반영

---

### US-HIS-004: 세션 삭제
**As a** 사용자
**I want to** 세션 기록을 삭제
**So that** 원치 않는 기록을 제거할 수 있다

**Acceptance Criteria:**
- AC-HIS-004-1: 상세 화면에서 "삭제" 버튼 표시
- AC-HIS-004-2: 삭제 전 확인 알림 표시 ("세션 삭제" / "이 세션 기록을 삭제하시겠습니까?")
- AC-HIS-004-3: 확인 시 레코드 삭제 및 저장소에서 제거
- AC-HIS-004-4: 삭제 후 상세 시트 자동 닫힘

---

### US-HIS-005: 진행 중 세션 표시
**As a** 사용자
**I want to** 진행 중인 세션을 구분하여 확인
**So that** 완료되지 않은 세션을 알 수 있다

**Acceptance Criteria:**
- AC-HIS-005-1: actualDuration이 nil인 레코드에 "진행 중" 배지 표시
- AC-HIS-005-2: 진행 중 레코드는 0.7 opacity로 표시
- AC-HIS-005-3: 길이(분) 대신 배지만 표시

## 3. UI Specifications

### 3.1 HistoryView Layout
```
┌─────────────────────────────────┐
│            기록                 │ ← Header
├─────────────────────────────────┤
│ 오늘                            │ ← Date Header
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 14:30        ★3       25분 │ │ ← RecordRow
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 10:15   [진행 중]          │ │ ← In-Progress Row
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 어제                            │
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 16:00        ★4       30분 │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 3.2 Header
| Property | Value |
|----------|-------|
| Text | "기록" |
| Font | title2, semibold |
| Alignment | center |
| Padding | 16pt vertical |

### 3.3 Date Header
| Property | Value |
|----------|-------|
| Font | subheadline |
| Color | secondary |
| Alignment | leading |
| Padding horizontal | 20pt (Spacing.lg) |
| Padding top | 16pt |

#### Date Format
| Condition | Format |
|-----------|--------|
| 오늘 | "오늘" |
| 어제 | "어제" |
| 올해 | "M월 d일 (E)" |
| 다른 해 | (현재 미구현) |

### 3.4 RecordRowView
| Property | Value |
|----------|-------|
| Background | cardBackground |
| Corner radius | large (12pt), continuous |
| Padding horizontal | 16pt |
| Padding vertical | 14pt |
| Margin horizontal | 20pt (Spacing.lg) |
| Row spacing | 12pt |

#### Row Elements
| Element | Position | Font | Color |
|---------|----------|------|-------|
| 시작 시간 | Leading | headline, semibold | primary |
| "진행 중" 배지 | Center (조건부) | caption2 | orange |
| 길이 | Center-right | subheadline | secondary |
| 집중도 (★N) | Trailing | caption (icon) + subheadline, medium | pomodoroAccent |

#### "진행 중" 배지
| Property | Value |
|----------|-------|
| Text | "진행 중" |
| Font | caption2 |
| Background | orange 20% opacity |
| Text color | orange |
| Corner radius | 4pt |
| Padding | 8pt horizontal, 4pt vertical |

#### In-Progress Row
| Property | Value |
|----------|-------|
| Opacity | 0.7 |
| 길이 표시 | 숨김 (배지만 표시) |

### 3.5 Empty State
| Property | Value |
|----------|-------|
| Component | ContentUnavailableView |
| Icon | clock.badge.questionmark |
| Title | "기록 없음" |
| Description | "첫 포모도로 세션을 완료하면\n여기에 기록이 표시됩니다" |

### 3.6 RecordDetailView

#### Drag Handle
| Property | Value |
|----------|-------|
| Size | 36 x 5pt |
| Color | gray 40% opacity |
| Shape | Capsule |
| Padding | 8pt top, 4pt bottom |

#### Portrait Layout
```
┌─────────────────────────────────┐
│          ─────                  │ ← Drag handle
├─────────────────────────────────┤
│         [Goal Text]            │
│    01.15 (월) 14:30 | 25분     │
├─────────────────────────────────┤
│ 집중도                          │
│ [1] [2] [3] [4] [5]            │
├─────────────────────────────────┤
│ 회고                            │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 메모                            │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│      [      저장      ]        │
│           삭제                  │
└─────────────────────────────────┘
```

#### Landscape Layout
```
┌─────────────────────────────────────────────────────────┐
│                        ─────                             │
│               [Goal Text] 01.15 14:30 | 25분            │
├────────────────────────┬────────────────────────────────┤
│ 집중도                  │ 회고                           │
│ [1] [2] [3] [4] [5]    │ ┌──────────────────────────┐   │
│                        │ └──────────────────────────┘   │
│                        │ 메모                           │
│                        │ ┌──────────────────────────┐   │
│                        │ └──────────────────────────┘   │
├────────────────────────┴────────────────────────────────┤
│         [  삭제  ]              [  저장  ]              │
└─────────────────────────────────────────────────────────┘
```

#### Header Section
| Property | Value |
|----------|-------|
| Goal font | title2, semibold |
| DateTime format (올해) | "MM.dd (E) HH:mm" |
| DateTime format (다른해) | "yyyy.MM.dd (E) HH:mm" |
| Duration format | "{N}분" (bold) |
| Separator | " \| " |
| Font | subheadline |
| Color | secondary |

#### Focus Level Buttons
(02-session-record.md 3.3과 동일)

#### Text Editors
| Property | Value |
|----------|-------|
| Background | cardBackground |
| Min height (Portrait) | 100pt |
| Min height (Landscape) | 80pt |
| Corner radius | 12pt |
| Padding | 8pt |

#### Save Button
| Property | Value |
|----------|-------|
| Height | 50pt (@ScaledMetric) |
| Background | pomodoroAccent |
| Text | "저장" (headline, white) |
| Corner radius | 12pt |
| Padding horizontal | 24pt |
| Padding bottom | 24pt (portrait), 16pt (landscape) |

#### Delete Button
| Property | Value (Portrait) | Value (Landscape) |
|----------|------------------|-------------------|
| Position | 하단 (저장 아래) | 좌측 (저장과 나란히) |
| Style | Text only | Full button |
| Text | "삭제" (subheadline) | "삭제" (headline, white) |
| Color | red | white on red 90% |

### 3.7 Delete Confirmation Alert
| Property | Value |
|----------|-------|
| Title | "세션 삭제" |
| Message | "이 세션 기록을 삭제하시겠습니까?" |
| Cancel button | "취소" |
| Delete button | "삭제" (destructive) |

## 4. Accessibility

### 4.1 Date Headers
| Property | Value |
|----------|-------|
| accessibilityTraits | .isHeader |

### 4.2 RecordRowView
| Property | Value |
|----------|-------|
| accessibilityElement | children: .combine |
| accessibilityLabel | "{HH:mm}, {N}분 세션, 집중도 {L}점" (완료) |
| accessibilityLabel | "{HH:mm}, 진행 중인 세션" (진행 중) |
| accessibilityHint | "탭하여 상세 보기" |

### 4.3 Empty State
| Property | Value |
|----------|-------|
| accessibilityElement | children: .combine |

### 4.4 Focus Level Buttons (Detail)
| Property | Value |
|----------|-------|
| accessibilityLabel | "집중도 {N}점" |
| accessibilityTraits (selected) | .isSelected |

### 4.5 Delete Button (Detail)
| Property | Value |
|----------|-------|
| accessibilityLabel | "세션 삭제" |
| accessibilityHint | "이 세션 기록을 영구적으로 삭제합니다" |

## 5. TabView Interaction

### 5.1 문제
시트 `onDismiss` 콜백이 닫힘 애니메이션 **중**에 발생하여, `scrollDisabled`를 바로 false로 설정하면 스와이프 제스처가 TabView 페이지 전환을 트리거할 수 있음.

### 5.2 해결책
```swift
.sheet(item: $selectedRecord, onDismiss: {
    // 시트 닫힘 애니메이션 완료까지 대기 (약 0.3초 + 버퍼)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        isDetailSheetPresented = false
    }
})
```

### 5.3 ContentView 연동
```swift
// ContentView에서
TabView(selection: $selectedTab) { ... }
    .scrollDisabled(isDetailSheetPresented)
```

## 6. Data Flow

### 6.1 화면 진입
```
HistoryView.onAppear
    └── HistoryViewModel.loadRecords()
        └── StorageService.load()
            └── records = loaded, sorted by startTime descending
```

### 6.2 레코드 선택
```
RecordRowView.onTapGesture
    └── selectedRecord = record
        └── onChange(selectedRecord)
            └── isDetailSheetPresented = true (ContentView에 전달)
```

### 6.3 저장
```
RecordDetailView.Save
    └── onSave(updatedRecord)
        └── HistoryViewModel.updateRecord(_:)
            ├── records 배열에서 업데이트
            └── StorageService.save(records:)
```

### 6.4 삭제
```
RecordDetailView.Delete (confirmed)
    └── onDelete()
        └── HistoryViewModel.deleteRecord(_:)
            ├── records 배열에서 제거
            └── StorageService.save(records:)
    └── dismiss() (시트 닫기)
```

## 7. Keyboard Navigation (RecordDetailView)

### 7.1 Focus Order
```
Reflection → Memo → (loop)
```

### 7.2 Keyboard Toolbar
| Element | Action |
|---------|--------|
| ↑ 버튼 | Memo → Reflection (disabled if Reflection) |
| ↓ 버튼 | Reflection → Memo (disabled if Memo) |
| "완료" 버튼 | 포커스 해제 |

---

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |

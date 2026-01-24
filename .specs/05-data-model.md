# Data Model Specification

## 1. PomodoroRecord

### 1.1 Schema
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | 고유 식별자 |
| `startTime` | Date | Yes | 세션 시작 시각 |
| `plannedDuration` | Int | Yes | 설정 시간 (초 단위) |
| `actualDuration` | Int? | No | 실제 진행 시간 (초), nil = 진행 중 |
| `goal` | String? | No | 세션 목표 |
| `focusLevel` | Int? | No | 집중도 (1-5) |
| `reflection` | String? | No | 회고 텍스트 |
| `memo` | String? | No | 메모 텍스트 |

### 1.2 Code Definition
```swift
struct PomodoroRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    let plannedDuration: Int
    var actualDuration: Int?
    var goal: String?
    var focusLevel: Int?
    var reflection: String?
    var memo: String?
}
```

### 1.3 Business Rules

#### US-DAT-001: 세션 상태 구분
**As a** 시스템
**I want to** actualDuration 필드로 세션 상태를 구분
**So that** 진행 중인 세션과 완료된 세션을 구별할 수 있다

**Acceptance Criteria:**
- AC-DAT-001-1: `actualDuration == nil`이면 세션이 아직 진행 중임을 의미
- AC-DAT-001-2: `actualDuration != nil`이면 세션이 완료됨을 의미
- AC-DAT-001-3: 진행 중 세션은 History에서 "진행 중" 배지로 표시

#### US-DAT-002: 집중도 범위 검증
**As a** 시스템
**I want to** focusLevel을 1-5 범위로 제한
**So that** 일관된 집중도 데이터를 유지할 수 있다

**Acceptance Criteria:**
- AC-DAT-002-1: focusLevel은 1, 2, 3, 4, 5 중 하나
- AC-DAT-002-2: 미입력 시 nil 저장
- AC-DAT-002-3: 기본값 3 (UI에서만 적용, 모델은 nil)

#### US-DAT-003: 빈 문자열 처리
**As a** 시스템
**I want to** 빈 문자열을 nil로 저장
**So that** 저장 공간을 절약하고 일관성을 유지할 수 있다

**Acceptance Criteria:**
- AC-DAT-003-1: `goal == ""`이면 nil로 저장
- AC-DAT-003-2: `reflection == ""`이면 nil로 저장
- AC-DAT-003-3: `memo == ""`이면 nil로 저장

## 2. PendingRecord

### 2.1 용도
타이머 완료 후 RecordView로 전달하기 위한 임시 구조체.
아직 사용자가 집중도/회고를 입력하지 않은 상태.

### 2.2 Schema
| Field | Type | Description |
|-------|------|-------------|
| `startTime` | Date | 세션 시작 시각 |
| `plannedDuration` | Int | 설정 시간 (초) |
| `actualDuration` | Int | 실제 시간 = plannedDuration + overSeconds |
| `goal` | String? | 세션 목표 |

### 2.3 Code Definition
```swift
struct PendingRecord {
    let startTime: Date
    let plannedDuration: Int
    let actualDuration: Int
    let goal: String?
}
```

## 3. Storage Service

### 3.1 저장 경로
| 조건 | 경로 |
|------|------|
| iCloud 사용 가능 | `iCloud.com.presence042.refomo/Documents/Refomo/records.json` |
| iCloud 불가 | `~/Documents/Refomo/records.json` |

### 3.2 API

#### `save(records:)`
전체 레코드 배열을 JSON 파일로 저장.
- **Input**: `[PomodoroRecord]`
- **Output**: void
- **특징**: Atomic write로 데이터 손상 방지

#### `load()`
JSON 파일에서 레코드 배열 로드.
- **Input**: void
- **Output**: `[PomodoroRecord]`
- **특징**: 파일 없거나 파싱 실패 시 빈 배열 반환

#### `append(record:)`
새 레코드 추가.
- **Input**: `PomodoroRecord`
- **Output**: void
- **동작**: load() → append → save()

#### `update(record:)`
기존 레코드 업데이트.
- **Input**: `PomodoroRecord`
- **Output**: void
- **동작**: load() → find by id → replace → save()
- **특징**: ID 매칭 실패 시 무시

### 3.3 Encoding
```swift
// Encoder
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = .prettyPrinted

// Decoder
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
```

## 4. Session State Flow

### 4.1 State Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                    세션 라이프사이클                          │
└─────────────────────────────────────────────────────────────┘

[Not Started]
     │
     │ 타이머 시작
     ▼
[Running] ◀──────────────────┐
     │                        │
     │ (메모 저장)            │
     ▼                        │
[In-Progress with Memo] ─────┘
     │  • PomodoroRecord 생성
     │  • actualDuration = nil
     │  • currentRecordId 저장
     │
     │ 타이머 완료
     ▼
[Completed]
     │  • actualDuration 업데이트
     │  • = plannedDuration + overSeconds
     │
     │ RecordView 표시
     ▼
[Recording]
     │
     ├─── [저장]              ├─── [건너뛰기]
     │    • focusLevel 저장   │    • 기존 레코드 유지
     │    • reflection 저장   │      (메모만 있는 상태)
     │    • memo 업데이트     │    • 또는 레코드 없음
     ▼                        ▼
[Fully Recorded]          [Partial/None]
```

### 4.2 Record Update Pattern

#### Case 1: 메모 없이 완료
1. 타이머 완료 → `showRecordView = true`
2. RecordView에서 저장 → 새 PomodoroRecord 생성
3. `StorageService.append()` 호출

#### Case 2: 메모 저장 후 완료
1. 타이머 실행 중 메모 저장 → 부분 레코드 생성
   - `actualDuration = nil`
   - `currentRecordId` 저장
2. 타이머 완료 → 레코드의 `actualDuration` 업데이트
3. RecordView에서 저장 → 기존 레코드 업데이트
4. `StorageService.update()` 호출

## 5. iCloud Sync

### 5.1 Configuration
```swift
// Container ID
private let containerID = "iCloud.com.presence042.refomo"

// Entitlements
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.presence042.refomo</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>
```

### 5.2 Sync Behavior
| 항목 | 설명 |
|------|------|
| 자동 동기화 | FileManager ubiquity container 사용 |
| 동기화 지연 | 일반적으로 10-30초 |
| 충돌 해결 | Last-write-wins |
| Fallback | iCloud 불가 시 로컬 Documents 사용 |

### 5.3 Setup Requirements
1. Xcode에서 iCloud capability 추가
2. iCloud Documents 활성화
3. Container ID 매칭 확인

## 6. ViewModel State Management

### 6.1 PomodoroViewModel
| Property | Type | Description |
|----------|------|-------------|
| `selectedMinutes` | Int | 선택된 분 (1-60) |
| `remainingSeconds` | Int | 남은 초 |
| `overSeconds` | Int | 초과 시간 (초) |
| `timerState` | TimerState | idle/running/paused/completed |
| `showRecordView` | Bool | RecordView 표시 여부 |
| `goalText` | String | 목표 텍스트 |
| `inProgressMemo` | String | 진행 중 메모 |
| `showMemoPanel` | Bool | 메모 패널 표시 여부 |
| `currentRecordId` | UUID? | 진행 중 레코드 ID (private) |

### 6.2 RecordViewModel
| Property | Type | Description |
|----------|------|-------------|
| `focusLevel` | Int | 집중도 (1-5), 기본값 3 |
| `reflection` | String | 회고 텍스트 |
| `memo` | String | 메모 텍스트 |
| `pendingRecord` | PendingRecord? | 대기 중인 레코드 |
| `existingRecordId` | UUID? | 업데이트할 레코드 ID |

### 6.3 HistoryViewModel
| Property | Type | Description |
|----------|------|-------------|
| `records` | [PomodoroRecord] | 전체 레코드 (최신순) |
| `groupedRecords` | [Date: [PomodoroRecord]] | 날짜별 그룹 (computed) |

---

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |

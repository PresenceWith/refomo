# ReFomo Specification Documents

ReFomo 앱의 기능, UI, UX를 정의하는 Spec 문서 모음입니다.

## 문서 구조

| 문서 | 설명 |
|------|------|
| [00-overview.md](00-overview.md) | 앱 개요, 디자인 원칙, 네비게이션 구조 |
| [01-timer.md](01-timer.md) | 타이머 기능 (PomodoroView) |
| [02-session-record.md](02-session-record.md) | 세션 기록 (RecordView) |
| [03-history.md](03-history.md) | 기록 조회/편집 (HistoryView, RecordDetailView) |
| [04-memo-panel.md](04-memo-panel.md) | 진행 중 메모 (MemoSidePanel) |
| [05-data-model.md](05-data-model.md) | 데이터 모델, 저장소, iCloud 동기화 |
| [06-design-system.md](06-design-system.md) | 디자인 토큰 (색상, 간격, 애니메이션) |

## ID 규칙

### User Story ID
- 형식: `US-{기능}-{번호}`
- 예: `US-TIM-001` (Timer 기능의 첫 번째 User Story)

| 접두사 | 기능 |
|--------|------|
| TIM | Timer (타이머) |
| REC | Record (세션 기록) |
| HIS | History (기록 조회) |
| MEM | Memo (메모 패널) |
| DAT | Data (데이터 모델) |

### Acceptance Criteria ID
- 형식: `AC-{US ID}-{번호}`
- 예: `AC-TIM-001-1` (US-TIM-001의 첫 번째 Acceptance Criteria)

## 문서 규칙

### 언어
- **기술 용어**: 영어 (State Machine, User Story, Acceptance Criteria 등)
- **설명 및 요구사항**: 한국어
- **코드/API 이름**: 영어 유지

### User Story 형식
```markdown
### US-XXX-NNN: 스토리 제목
**As a** 사용자
**I want to** 원하는 기능
**So that** 달성하려는 목표

**Acceptance Criteria:**
- AC-XXX-NNN-1: 검증 가능한 조건
- AC-XXX-NNN-2: ...
```

### UI Spec 형식
```markdown
### 컴포넌트 이름
- Size: 크기 (@ScaledMetric 여부)
- Color: 색상 토큰
- Corner radius: 반경 토큰
- Animation: 조건부 애니메이션
```

## 버전 관리

각 spec 문서 하단에 버전 이력을 기록합니다:

```markdown
---
## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |
```

## 관련 소스 파일

| Spec 문서 | 주요 참조 파일 |
|-----------|----------------|
| 01-timer.md | `Views/PomodoroView.swift`, `ViewModels/PomodoroViewModel.swift` |
| 02-session-record.md | `Views/RecordView.swift`, `ViewModels/RecordViewModel.swift` |
| 03-history.md | `Views/HistoryView.swift`, `ViewModels/HistoryViewModel.swift` |
| 04-memo-panel.md | `Views/Components/MemoSidePanel.swift` |
| 05-data-model.md | `Models/PomodoroRecord.swift`, `Services/StorageService.swift` |
| 06-design-system.md | `DesignSystem.swift`, `Services/SoundService.swift` |

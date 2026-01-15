# Refomo 프로젝트 개요

## 프로젝트 소개
**Refomo**는 iOS용 뽀모도로 타이머 앱입니다.

## 주요 기능
- 원형 다이얼로 시간 선택 (1-60분)
- 세션 기록 (집중도, 회고 메모)
- iCloud 동기화

## 기술 스택
- **언어**: Swift
- **프레임워크**: SwiftUI
- **IDE**: Xcode
- **최소 타겟**: iOS (iPhone)

## 아키텍처: MVVM

### 폴더 구조
```
refomo/refomo/
├── refomoApp.swift          # 앱 진입점
├── ContentView.swift        # 메인 뷰
├── DesignSystem.swift       # 디자인 토큰
├── ViewModels/
│   ├── PomodoroViewModel.swift   # 타이머 상태 관리
│   ├── RecordViewModel.swift     # 세션 기록 관리
│   └── HistoryViewModel.swift    # 히스토리 관리
├── Views/
│   ├── PomodoroView.swift        # 타이머 화면
│   ├── RecordView.swift          # 기록 화면
│   ├── HistoryView.swift         # 히스토리 화면
│   └── Components/               # 재사용 컴포넌트
├── Models/
│   └── PomodoroRecord.swift      # 세션 데이터 모델
└── Services/
    ├── StorageService.swift      # JSON 파일 저장 (iCloud)
    └── SoundService.swift        # 햅틱/사운드
```

## 타이머 상태 머신
```
idle → running → paused → running (반복)
         ↓ (시간 종료)
    completed → RecordView → idle
```
- Long press: 타이머 리셋

## UI 언어
- 한국어
- 주요 필드: 집중도, 회고, 메모

## iCloud Container
`iCloud.presence042.refomo`

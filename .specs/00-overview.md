# App Overview Specification

## 1. Product Vision

### 1.1 앱 목적
ReFomo는 포모도로 기법을 활용하여 사용자의 집중력 향상을 돕는 iOS 네이티브 타이머 앱입니다.

### 1.2 타겟 사용자
- 지식 노동자 (개발자, 디자이너, 작가 등)
- 학생
- 집중력 향상이 필요한 모든 사용자

### 1.3 플랫폼 요구사항
- **OS**: iOS 17.0+
- **Device**: iPhone (iPad 미지원)
- **Orientation**: Portrait 및 Landscape 지원

## 2. Design Principles

### 2.1 미니멀리즘
- 핵심 기능에 집중한 단순한 UI
- 불필요한 설정 옵션 최소화
- 타이머에 시선을 집중시키는 레이아웃

### 2.2 Accessibility First
- 모든 UI 요소에 VoiceOver 지원
- Dynamic Type을 통한 텍스트 크기 조절
- Reduce Motion 설정 존중
- 햅틱 피드백으로 시각 외 피드백 제공

### 2.3 HIG 준수
- Apple Human Interface Guidelines 준수
- 네이티브 iOS 컴포넌트 활용
- 시스템 색상 및 다크 모드 자동 지원

## 3. Navigation Architecture

### 3.1 화면 구조
```
refomoApp (Entry Point)
└── ContentView (Root Container)
    ├── SplashView (초기 스플래시, 자동 전환)
    └── TabView (page-based, 2 tabs)
        ├── Tab 0: HistoryView (기록)
        └── Tab 1: PomodoroView (타이머, 기본 화면)
```

### 3.2 네비게이션 패턴

| 화면 전환 | 방식 | 트리거 |
|----------|------|--------|
| History ↔ Timer | TabView 스와이프 | 좌/우 스와이프 |
| Timer → RecordView | Full Screen Cover | 타이머 완료 후 "완료" 버튼 탭 |
| History → RecordDetailView | Sheet Modal | 기록 행 탭 |
| Timer → MemoSidePanel | Slide Animation | 좌측 스와이프 또는 FAB 탭 |

### 3.3 화면 흐름도

```
┌─────────────────────────────────────────────────────────────┐
│                         TabView                              │
├─────────────────────┬───────────────────────────────────────┤
│                     │                                        │
│   HistoryView       │   PomodoroView                        │
│   (Tab 0)          │   (Tab 1, Default)                    │
│                     │                                        │
│   ┌─────────────┐  │   ┌─────────────────────────────────┐  │
│   │ Record Row  │──┼──▶│ Timer Circle                    │  │
│   │ Record Row  │  │   │                                 │  │
│   │ Record Row  │  │   │ ┌───────────┐ ┌──────────────┐  │  │
│   └─────────────┘  │   │ │ Goal Input│ │ MemoSidePanel│  │  │
│         │          │   │ └───────────┘ │ (Overlay)    │  │  │
│         ▼          │   │               └──────────────┘  │  │
│   ┌─────────────┐  │   │                                 │  │
│   │RecordDetail │  │   │ [완료 버튼]                      │  │
│   │  (Sheet)    │  │   └─────────────────────────────────┘  │
│   └─────────────┘  │              │                          │
│                     │              ▼                          │
│                     │   ┌─────────────────────────────────┐  │
│                     │   │ RecordView (Full Screen Cover) │  │
│                     │   └─────────────────────────────────┘  │
└─────────────────────┴───────────────────────────────────────┘
```

## 4. Global Accessibility Requirements

### 4.1 VoiceOver
- 모든 interactive 요소에 `accessibilityLabel` 제공
- 상태 변화를 설명하는 `accessibilityHint` 제공
- 상태에 따른 동적 레이블 업데이트

### 4.2 Dynamic Type
- 모든 고정 크기에 `@ScaledMetric` 적용
- 레이아웃이 텍스트 크기에 따라 적응

### 4.3 Reduce Motion
- 모든 애니메이션에 `AnimationConfig.reduceMotion` 체크
- Reduce Motion 활성화 시 애니메이션 비활성화

### 4.4 Keyboard Navigation
- Tab/Shift+Tab으로 필드 간 이동
- Arrow keys로 값 조절
- Enter로 액션 실행

## 5. Localization

### 5.1 현재 지원 언어
- 한국어 (Primary)

### 5.2 언어 규칙
- **UI 텍스트**: 한국어
- **코드 (변수명, 함수명, 주석)**: 영어
- **복잡한 비즈니스 로직 주석**: 한국어 허용

## 6. Data Sync

### 6.1 iCloud 동기화
- 자동 iCloud Documents 동기화
- iCloud 불가 시 로컬 저장소 fallback
- Container ID: `iCloud.com.presence042.refomo`

### 6.2 동기화 동작
- 저장 즉시 iCloud에 업로드
- 기기 간 동기화 지연: 10-30초 (일반적)
- 충돌 해결: Last-write-wins

---

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |

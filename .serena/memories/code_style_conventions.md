# 코드 스타일 및 컨벤션

## Swift 스타일

### ViewModels
- `@MainActor` 어노테이션 사용
- `ObservableObject` 프로토콜 준수
- `@Published` 프로퍼티로 상태 관리

```swift
@MainActor
class PomodoroViewModel: ObservableObject {
    @Published var timerState: TimerState = .idle
}
```

### Views
- SwiftUI 뷰 구조체
- Portrait/Landscape 레이아웃 지원
- 작은 컴포넌트는 `Views/Components/` 에 분리

### Services
- 싱글톤 패턴 사용

## 디자인 시스템 (DesignSystem.swift)

### 색상
- `Color.pomodoroAccent` - 주요 액센트 색상 (Asset Catalog)
- `Color.cardBackground`, `Color.inputBackground` 등

### 간격 (8pt Grid)
```swift
Spacing.xs   // 4pt
Spacing.sm   // 8pt
Spacing.md   // 16pt
Spacing.lg   // 24pt
Spacing.xl   // 32pt
Spacing.xxl  // 48pt
```

### 모서리 반경
```swift
CornerRadius.small   // 8pt
CornerRadius.medium  // 12pt
CornerRadius.large   // 16pt
CornerRadius.sheet   // 24pt
```

### 그림자
```swift
ShadowStyle.subtle
ShadowStyle.card
```

### 애니메이션
- `accessibilityReduceMotion` 환경 변수 존중
- `AnimationConfig` 사용

## 접근성
- 모든 인터랙티브 요소에 한국어 접근성 레이블/힌트
- `@Environment(\.accessibilityReduceMotion)` 체크
- `@ScaledMetric`으로 Dynamic Type 지원

## 네이밍
- 한국어 UI 필드명: 집중도, 회고, 메모
- Swift 코드는 영어 사용

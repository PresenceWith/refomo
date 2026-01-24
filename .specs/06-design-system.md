# Design System Specification

## 1. Colors

### 1.1 Accent Color
| Token | Source | 용도 |
|-------|--------|------|
| `Color.pomodoroAccent` | Asset Catalog (PomodoroAccent.colorset) | Primary 액션, 선택 상태, 진행률 |

### 1.2 Semantic Colors
| Token | UIKit 매핑 | 용도 |
|-------|------------|------|
| `Color.cardBackground` | `UIColor.secondarySystemBackground` | 카드 배경 |
| `Color.inputBackground` | `UIColor.tertiarySystemBackground` | 텍스트 입력 필드 배경 |
| `Color.primaryText` | `UIColor.label` | 주요 텍스트 |
| `Color.secondaryText` | `UIColor.secondaryLabel` | 보조 텍스트 |
| `Color.tertiaryText` | `UIColor.tertiaryLabel` | 힌트, 플레이스홀더 |

### 1.3 System Colors (직접 사용)
| Color | 용도 |
|-------|------|
| `Color(.systemBackground)` | 화면 배경 |
| `Color(.secondarySystemBackground)` | 메모 패널 텍스트 에디터 배경 |
| `Color(.tertiarySystemBackground)` | 메모 패널 배경 |
| `Color(.placeholderText)` | 플레이스홀더 텍스트 |
| `Color.orange` | 진행 중 배지 |
| `Color.red` | 삭제 버튼, 글자 수 초과 경고 |

## 2. Spacing (8pt Grid)

### 2.1 Spacing Tokens
| Token | Value | 용도 |
|-------|-------|------|
| `Spacing.xs` | 4pt | 아이콘-텍스트 간격 |
| `Spacing.sm` | 8pt | 밀집 그룹핑 |
| `Spacing.md` | 16pt | 콘텐츠 패딩 |
| `Spacing.lg` | 20pt | 화면 가장자리 마진 |
| `Spacing.xl` | 24pt | 섹션 간격 |
| `Spacing.xxl` | 32pt | 주요 섹션 간격 |

### 2.2 사용 예시
```swift
// 화면 가장자리 마진
.padding(.horizontal, Spacing.lg)  // 20pt

// 섹션 간격
VStack(spacing: Spacing.xxl) { ... }  // 32pt

// 버튼 내부 패딩
.padding(.horizontal, Spacing.md)  // 16pt
.padding(.vertical, Spacing.sm)    // 8pt
```

## 3. Corner Radius

### 3.1 Radius Tokens
| Token | Value | 용도 |
|-------|-------|------|
| `CornerRadius.small` | 8pt | 작은 버튼, 배지 |
| `CornerRadius.medium` | 10pt | 입력 필드, 텍스트 에디터 |
| `CornerRadius.large` | 12pt | 카드, 기록 행 |
| `CornerRadius.sheet` | 16pt | 시트 상단 모서리 |
| `CornerRadius.pill(height:)` | height / 2 | 완전한 둥근 버튼 (Pill) |

### 3.2 사용 예시
```swift
// 카드 스타일
.clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))

// 완료 버튼 (pill)
.cornerRadius(22)  // height 44의 절반
```

## 4. Typography

### 4.1 Font Styles
| 요소 | Font | Size | Weight | Design |
|------|------|------|--------|--------|
| 타이머 표시 | System | 32pt (@ScaledMetric) | Light | Monospaced |
| 화면 제목 | System | Title2 | Semibold | Default |
| 섹션 헤더 | System | Headline | - | Default |
| 버튼 텍스트 | System | Headline | - | Default |
| 본문 | System | Body | - | Default |
| 보조 텍스트 | System | Subheadline | - | Default |
| 캡션 | System | Caption2 | - | Default |

### 4.2 Dynamic Type 지원
모든 고정 크기에 `@ScaledMetric` 적용:
```swift
@ScaledMetric(relativeTo: .largeTitle) private var timerFontSize: CGFloat = 32
@ScaledMetric(relativeTo: .title2) private var focusButtonSize: CGFloat = 50
@ScaledMetric(relativeTo: .headline) private var saveButtonHeight: CGFloat = 50
@ScaledMetric(relativeTo: .body) private var padding: CGFloat = 16
@ScaledMetric(relativeTo: .footnote) private var hintFontSize: CGFloat = 12
```

## 5. Shadows

### 5.1 Shadow Levels
| Level | Name | Color | Radius | Offset | 용도 |
|-------|------|-------|--------|--------|------|
| 1 | `ShadowStyle.subtle` | black 8% | 4pt | (0, 1) | 드래그 핸들 |
| 2 | `ShadowStyle.card` | black 12% | 8pt | (0, 2) | 카드, 모달 |

### 5.2 사용 예시
```swift
// 드래그 핸들
.shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)

// FAB 버튼
.shadow(radius: 4)

// 포커스 상태 버튼
.shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
```

## 6. Animations

### 6.1 Reduce Motion 지원
```swift
struct AnimationConfig {
    static var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    static func animation(_ duration: Double = normal) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: duration)
    }
}
```

### 6.2 Animation Durations
| Token | Duration | 용도 |
|-------|----------|------|
| `AnimationConfig.fast` | 0.15s | 선택 변경 |
| `AnimationConfig.normal` | 0.3s | 상태 전환 |
| `AnimationConfig.slow` | 0.5s | 주요 뷰 변경 |

### 6.3 Gesture Animations
| 용도 | Animation | Parameters |
|------|-----------|------------|
| 메모 패널 슬라이드 | Spring | response: 0.45, dampingFraction: 0.82 |
| 드래그 핸들 스케일 | EaseOut | duration: 0.1 |
| 타이머 상태 전환 | EaseInOut | duration: 0.3 |
| 시간 표시 페이드 | EaseOut | duration: 0.8 |
| 포커스 링 표시 | EaseInOut | duration: 0.2 |

### 6.4 Conditional Animation Modifier
```swift
extension View {
    func animateIfAllowed<V: Equatable>(_ value: V, duration: Double = AnimationConfig.fast) -> some View {
        self.animation(AnimationConfig.reduceMotion ? nil : .easeInOut(duration: duration), value: value)
    }
}
```

## 7. Haptic Feedback

### 7.1 Haptic Events
| Event | Style | 용도 |
|-------|-------|------|
| Timer 시작/일시정지/재개 | Light | 타이머 상태 변경 |
| Timer 리셋 | Medium | 중요 액션 |
| Timer 완료 | Heavy | 주요 이벤트 |
| 선택 변경 | Selection | 분 조절, 집중도 선택 |
| 저장 액션 | Medium | 기록 저장 |
| 메모 패널 열기 | Light | 제스처 완료 |
| 메모 패널 닫기 | Medium | 제스처 완료 + 저장 |

### 7.2 SoundService API
```swift
SoundService.shared.playHaptic(.light)    // 가벼운 임팩트
SoundService.shared.playHaptic(.medium)   // 중간 임팩트
SoundService.shared.playHaptic(.heavy)    // 강한 임팩트
SoundService.shared.playSelectionHaptic() // 선택 변경
SoundService.shared.playCompletionSound() // 시스템 사운드 (1103)
```

## 8. Component Patterns

### 8.1 Primary Button
```swift
// 현재 구현
Text("저장")
    .font(.headline)
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .frame(height: saveButtonHeight)  // 50pt @ScaledMetric
    .background(Color.pomodoroAccent)
    .cornerRadius(12)

// iOS 26+ 예정
.primaryButtonStyle(accent: .pomodoroAccent)
// → .glassEffect(.regular.tint(accent)) 적용
```

### 8.2 Focus Level Button
```swift
Button { ... } label: {
    Text("\(level)")
        .font(.title2)
        .fontWeight(.medium)
        .frame(width: focusButtonSize, height: focusButtonSize)  // 50pt @ScaledMetric
        .background(isSelected ? Color.pomodoroAccent : Color.cardBackground)
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(12)
        .scaleEffect(isSelected ? 1.05 : 1.0)
}
```

### 8.3 Text Editor
```swift
TextEditor(text: $text)
    .frame(minHeight: 100)
    .padding(8)
    .background(Color.inputBackground)
    .cornerRadius(12)
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.pomodoroAccent, lineWidth: isFocused ? 2 : 0)
    )
```

### 8.4 Record Row Card
```swift
HStack(spacing: 12) { ... }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Color.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large, style: .continuous))
    .padding(.horizontal, Spacing.lg)
```

## 9. Responsive Layout

### 9.1 Orientation Detection
```swift
@Environment(\.verticalSizeClass) private var verticalSizeClass

private var isLandscape: Bool {
    verticalSizeClass == .compact
}
```

### 9.2 Layout Adaptations
| Component | Portrait | Landscape |
|-----------|----------|-----------|
| 타이머 서클 크기 | min(width, height) * 0.8 | min(width * 0.5, height * 0.85) |
| 메모 패널 너비 | 300pt | 250pt |
| 레이아웃 | VStack | HStack (55% / 45%) |
| 텍스트 에디터 높이 | 100pt | 80pt |

---

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-01-22 | 초기 버전 |

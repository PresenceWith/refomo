# ReFomo - iOS Pomodoro Timer

> 심플하고 우아한 iOS용 뽀모도로 타이머 with 세션 트래킹 & iCloud 동기화

## 주요 기능

- **원형 타임 다이얼** - 직관적인 1-60분 타이머 설정
- **세션 기록** - 집중도, 회고, 메모 트래킹
- **iCloud 동기화** - 기기 간 데이터 자동 동기화
- **접근성 우선** - VoiceOver, Dynamic Type, Reduce Motion 지원
- **네이티브 iOS 디자인** - SwiftUI, 다크모드, 한국어 로컬라이제이션

## 기술 스택

- **Language**: Swift
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **Storage**: iCloud + JSON
- **Min iOS**: iOS 17.0+

## 프로젝트 구조

```
refomo/refomo/
├── Models/            # 데이터 모델 (PomodoroRecord)
├── ViewModels/        # MVVM 뷰모델
├── Views/             # SwiftUI 뷰
│   └── Components/    # 재사용 컴포넌트
├── Services/          # 비즈니스 로직 (Storage, Sound)
└── DesignSystem.swift # 디자인 토큰
```

## 시작하기

### 필수 사항
- Xcode 15.0+
- iOS 17.0+ 기기/시뮬레이터
- Apple Developer 계정 (iCloud용)

### 설치

1. 저장소 클론:
```bash
git clone https://github.com/PresenceWith/refomo.git
cd refomo
```

2. 프로젝트 열기:
```bash
open refomo/refomo.xcodeproj
```

3. iCloud 설정:
   - `iCloud.com.presence042.refomo` 컨테이너 ID 업데이트
   - Xcode에서 iCloud 기능 활성화

4. 빌드 및 실행 (⌘R)

## 개발

### 코드 스타일
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) 준수
- ViewModel에 `@MainActor` 사용
- UI 텍스트: 한국어, 코드: 영어

### 커밋 컨벤션
```
[type] Subject (최대 50자)

[feat]     - 새로운 기능
[fix]      - 버그 수정
[refactor] - 코드 리팩토링
[test]     - 테스트 추가/수정
[docs]     - 문서 작성
[chore]    - 빌드, 의존성, 설정
```

## 아키텍처

### MVVM 패턴
- **Models**: `PomodoroRecord` (Codable, Identifiable)
- **ViewModels**: `@Published` 속성으로 상태 관리
- **Views**: SwiftUI 선언형 UI
- **Services**: 싱글톤 비즈니스 로직

### 타이머 상태 머신
```
idle → running → paused ⟲ running
         ↓ (시간 만료)
    completed → RecordView → idle
```

## 라이선스

MIT

## 제작자

**Presence**
GitHub: [@PresenceWith](https://github.com/PresenceWith)

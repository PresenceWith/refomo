# 작업 완료 시 체크리스트

## 코드 변경 후

### 1. 빌드 확인
```bash
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo -configuration Debug build
```
또는 Xcode에서 ⌘B

### 2. 테스트 실행
```bash
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo test \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
또는 Xcode에서 ⌘U

### 3. 접근성 확인
- 새로운 UI 요소에 접근성 레이블 추가
- `accessibilityReduceMotion` 존중 여부 확인

### 4. 디자인 시스템 준수
- `DesignSystem.swift`의 토큰 사용 확인
- 하드코딩된 색상/간격 없는지 확인

### 5. Git 커밋
```bash
git add .
git commit -m "변경 내용 설명"
```

## 새 기능 추가 시

1. MVVM 패턴 준수
2. 한국어 UI 텍스트 사용
3. 필요시 iCloud 동기화 고려
4. 테스트 케이스 추가

## 주의사항

- `@MainActor` 어노테이션 누락 주의
- `@Published` 프로퍼티 변경 시 메인 스레드 확인
- 애니메이션 추가 시 `AnimationConfig` 사용

# 개발 명령어

## Xcode 프로젝트 열기
```bash
open refomo/refomo.xcodeproj
```

## 빌드
```bash
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo -configuration Debug build
```

## 테스트 실행
```bash
# 전체 테스트
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo test \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# 단일 테스트
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo test \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:refomoTests/refomoTests/example
```

## 시뮬레이터 목록 확인
```bash
xcrun simctl list devices available
```

## 클린 빌드
```bash
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo clean
```

## Git 명령어 (Darwin/macOS)
```bash
git status
git add .
git commit -m "메시지"
git log --oneline -10
```

## 파일 탐색 (Darwin)
```bash
ls -la
find . -name "*.swift" -type f
grep -r "검색어" --include="*.swift" .
```

## 참고
- 대부분의 개발 작업은 Xcode에서 직접 수행 권장
- 시뮬레이터 이름은 환경에 따라 다를 수 있음

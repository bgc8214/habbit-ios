# 데이터 초기화 가이드

습관이 저장되지 않거나 표시되지 않을 때 데이터베이스를 초기화하는 방법입니다.

## 시뮬레이터 데이터 초기화

### 방법 1: 앱 삭제 후 재설치
1. 시뮬레이터에서 HabbitApp 아이콘 길게 누르기
2. "앱 제거" 선택
3. Xcode에서 다시 Run (⌘+R)

### 방법 2: 시뮬레이터 초기화
```bash
# 시뮬레이터 완전 초기화
xcrun simctl shutdown all
xcrun simctl erase all

# 또는 특정 시뮬레이터만
xcrun simctl erase "iPhone 16 Pro Max"
```

### 방법 3: SwiftData 저장소 직접 삭제
```bash
# 시뮬레이터 앱 데이터 찾기
xcrun simctl get_app_container booted com.yourcompany.HabbitApp data

# 출력된 경로로 이동하여 삭제
# 예: ~/Library/Developer/CoreSimulator/Devices/.../data/
rm -rf ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Application\ Support/default.store
```

## 실제 기기 데이터 초기화

1. 설정 > 일반 > iPhone 저장공간
2. HabbitApp 찾기
3. "앱 삭제" 선택
4. Xcode에서 다시 설치

## 코드에서 초기화 (개발 중에만 사용)

HabbitAppApp.swift를 임시로 수정:

```swift
var sharedModelContainer: ModelContainer = {
    let schema = Schema([
        Habit.self,
        DailyRecord.self,
    ])

    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true  // ← 메모리에만 저장 (재시작 시 삭제)
    )

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
```

테스트 후 다시 `isStoredInMemoryOnly: false`로 변경하세요.

## 문제 해결 체크리스트

습관이 저장되지 않을 때:

- [ ] Xcode 콘솔에서 "✅ modelContext.save() 완료" 로그 확인
- [ ] "✅ 데이터베이스 전체 습관 수: X" 로그 확인
- [ ] 화면에 "습관 수: 0" 표시되는지 확인
- [ ] 앱 삭제 후 재설치
- [ ] 다른 시뮬레이터에서 테스트
- [ ] Clean Build (⇧⌘K) 후 다시 빌드

## 로그 확인

Xcode에서 콘솔 로그 확인:
- `🔄` : 작업 시작
- `✅` : 작업 성공
- `❌` : 작업 실패

습관 추가 시 예상 로그:
```
🔄 습관 추가 시작: 스페인어 학습
   - MINI: 단어 2개
   - MORE: 단어 5개
   - MAX: 단어 10개
✅ Habit 객체 생성됨 - ID: ...
✅ modelContext.insert() 완료
✅ modelContext.save() 완료
✅ 데이터베이스 전체 습관 수: 1
   - 스페인어 학습 (isActive: true)
✅ fetchHabits() 완료, viewModel.habits.count: 1
```

이 로그가 나오지 않으면 저장 단계에서 실패한 것입니다.

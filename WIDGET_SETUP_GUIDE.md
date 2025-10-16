# 위젯 설정 가이드

HabbitApp 위젯을 활성화하려면 Xcode에서 Widget Extension 타겟을 추가해야 합니다.

## 📱 위젯 타겟 추가하기

### 1단계: Widget Extension 추가

1. Xcode에서 `HabbitApp.xcodeproj` 프로젝트 열기
2. 프로젝트 네비게이터에서 최상위 프로젝트 파일 선택
3. 메뉴에서 **File > New > Target** 선택
4. **Widget Extension** 템플릿 선택
5. 다음 정보 입력:
   - Product Name: `HabbitAppWidget`
   - Language: Swift
   - Include Configuration Intent: 체크 해제
6. **Finish** 클릭
7. "Activate HabbitAppWidget scheme?" 팝업 → **Activate** 선택

### 2단계: 기본 파일 교체

1. Xcode가 자동 생성한 다음 파일들을 **삭제**:
   - `HabbitAppWidget/HabbitAppWidget.swift`
   - `HabbitAppWidget/HabbitAppWidgetBundle.swift`
   - `HabbitAppWidget/Assets.xcassets` (선택사항)

2. 프로젝트 루트의 `/HabbitAppWidget/HabbitAppWidget.swift` 파일을 위젯 타겟에 추가:
   - Finder에서 파일 선택
   - Xcode 프로젝트 네비게이터의 `HabbitAppWidget` 폴더로 드래그
   - 팝업에서 다음 옵션 선택:
     - ✅ Copy items if needed
     - ✅ HabbitAppWidget (target)
     - ❌ HabbitApp (target - 체크 해제)

### 3단계: 모델 파일 공유 설정

위젯과 메인 앱이 데이터를 공유하도록 모델 파일들을 위젯 타겟에도 추가:

1. 다음 파일들을 선택:
   - `HabbitApp/Models/CompletionLevel.swift`
   - `HabbitApp/Models/Habit.swift`
   - `HabbitApp/Models/DailyRecord.swift`

2. File Inspector (⌥⌘1) 열기

3. **Target Membership** 섹션에서:
   - ✅ HabbitApp
   - ✅ HabbitAppWidget (체크 추가)

### 4단계: App Group 설정 (필수)

위젯과 앱이 SwiftData를 공유하려면 App Group이 필요합니다.

#### 메인 앱 설정

1. 프로젝트 설정에서 **HabbitApp** 타겟 선택
2. **Signing & Capabilities** 탭 클릭
3. **+ Capability** 버튼 클릭
4. **App Groups** 선택
5. **+** 버튼 클릭하여 새 App Group 추가:
   ```
   group.com.habbit.HabbitApp
   ```

#### 위젯 타겟 설정

1. 프로젝트 설정에서 **HabbitAppWidget** 타겟 선택
2. **Signing & Capabilities** 탭 클릭
3. **+ Capability** 버튼 클릭
4. **App Groups** 선택
5. 메인 앱과 **동일한** App Group 선택:
   ```
   group.com.habbit.HabbitApp
   ```

### 5단계: SwiftData 컨테이너 설정 업데이트

App Group을 사용하도록 코드를 수정해야 합니다.

#### `HabbitAppApp.swift` 수정

```swift
import SwiftUI
import SwiftData

@main
struct HabbitAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Habit.self,
            DailyRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.habbit.HabbitApp")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

#### `HabbitAppWidget.swift`의 `Provider` 수정

```swift
private func fetchHabits() -> [HabitWidgetData] {
    let schema = Schema([
        Habit.self,
        DailyRecord.self,
    ])
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        groupContainer: .identifier("group.com.habbit.HabbitApp")
    )
    
    guard let container = try? ModelContainer(for: schema, configurations: [modelConfiguration]) else {
        return []
    }
    
    // ... 나머지 코드 동일
}
```

## 🧪 위젯 테스트하기

### 시뮬레이터에서 테스트

1. Xcode에서 **HabbitAppWidget** scheme 선택
2. ▶️ Run 버튼 클릭
3. 위젯 종류 선택:
   - Small
   - Medium
4. 위젯이 시뮬레이터 홈 화면에 추가됨

### 실제 기기에서 테스트

1. 앱을 기기에 설치
2. 홈 화면에서 빈 공간 길게 누르기
3. 왼쪽 상단 **+** 버튼 터치
4. "HabbitApp" 검색
5. 원하는 위젯 크기 선택
6. **위젯 추가** 터치

## 🎨 위젯 종류

### Small Widget (소형)
- 습관 1개 표시
- MINI/MORE/MAX 완료 상태 표시
- 간단한 체크 인디케이터

### Medium Widget (중형)
- 습관 2개 표시
- 각 습관의 완료 상태
- "오늘의 습관" 헤더

## 🔄 위젯 업데이트 타이밍

위젯은 다음 시점에 자동으로 업데이트됩니다:
- 자정 (매일 00:00)
- 앱에서 습관 완료 시
- 시스템이 결정한 적절한 시점

## ⚠️ 문제 해결

### "Cannot find type in scope" 에러
→ 모델 파일들이 위젯 타겟에 포함되어 있는지 확인

### 위젯에 데이터가 표시되지 않음
→ App Group 설정이 양쪽 타겟에 모두 추가되었는지 확인
→ App Group 이름이 정확히 일치하는지 확인

### 빌드는 되지만 위젯이 작동하지 않음
→ Signing & Capabilities에서 App Groups가 활성화되어 있는지 확인
→ SwiftData 컨테이너가 groupContainer를 사용하도록 설정되었는지 확인

## 📝 참고사항

- 위젯은 읽기 전용입니다 (iOS 17 기준)
- iOS 17+에서는 위젯에서 직접 상호작용 가능 (Button, Toggle 등)
- 위젯은 15분마다 최대 업데이트 가능 (시스템 제한)
- 위젯은 백그라운드에서 실행되므로 메모리 제한이 있습니다

## 🚀 다음 단계

위젯이 성공적으로 작동하면:
1. 위젯 인터랙션 추가 (iOS 17+)
2. 위젯 구성 옵션 추가 (Configuration Intent)
3. 다양한 크기의 위젯 디자인 개선
4. 위젯 애니메이션 효과 추가

---

궁금한 점이 있으면 README.md를 참고하세요!


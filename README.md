# 필링 (Pilling) - 여성호르몬제 복용 관리 앱

<div align="center">
  <img width="400" alt="필링 앱 로고" src="https://github.com/user-attachments/assets/43436be2-edc8-4b0b-8f3b-248f5ad27e24">
  <br>
  <br>
  <b>필링(Pilling)</b>은 <b>여성호르몬제</b>를 <b>제시간</b>에 <b>복용</b>하게 하고, <b>간단하게 기록하는 것</b>을 <b>돕는</b> 앱입니다.
  <br>
  <br>
  My happy Pilling Time! Everyday is a growing.
  <br>
  <br>
  <img width="495" alt="필링 앱 스크린샷" src="https://github.com/user-attachments/assets/42d8c988-aa55-4b69-88ee-f57707a63692">
</div>

## 프로젝트 개요

여성호르몬제를 규칙적으로 복용하고 간단하게 기록할 수 있도록 돕는 iOS 앱

**기간:** 2024.05 - 2024.07 (팀 개발) → 2025.10 - 진행 중 (개인 리팩토링)  
**역할:** iOS 개발  
**배포 타겟:** iOS 16+

**GitHub:** [Pilling-iOS](https://github.com/piriram/Pilling-iOS)  
**App Store:** [다운로드](https://apps.apple.com/kr/app/pilling/id6753967952)

---

## 주요 기능

- 약마다 다른 사이클 직접 설정 지원 (복용일 + 휴약일)
- 복용 시간 ±2시간 허용 범위 내 상태 추적
- 9가지 세분화된 복용 상태 시각화
- 홈 화면 위젯을 통한 즉시 확인
- 복용 패턴 기반 맞춤 메시지 제공

---

## 기술 스택

**UI / Presentation**
- UIKit
- SnapKit
- WidgetKit
- Diffable Data Source

**Architecture**
- MVVM
- Clean Architecture
- Repository Pattern

**Reactive & State Handling**
- RxSwift
- NotificationCenter

**Data Layer**
- CoreData
- App Groups

---

## 핵심 구현 사항

### 1. PillStatus Enum 세분화

**문제 인식**

피임약 복용 앱에서 단순히 "복용함/안함"만으로는 사용자의 실제 복용 패턴을 정확히 추적할 수 없었습니다.

- "오늘 복용 예정"과 "오늘 2시간 지났는데 안 먹음"을 구분 불가
- "정시에 먹음"과 "2시간 늦게 먹음"을 구분 불가
- 과거에 누락된 복용과 미래 예정 복용을 동일하게 처리
- 휴약기를 별도로 표현 불가

**해결 방법**

복용 시간 ±2시간 허용 범위와 날짜를 기준으로 복용 상태를 9가지로 세분화했습니다.

```swift
enum PillStatus {
    // 과거
    case taken              // 정시 복용 완료
    case takenDelayed       // 지연 복용 (2시간 초과)
    case missed             // 누락
    
    // 오늘
    case todayNotTaken      // 아직 안 먹음 (2시간 이내)
    case todayTaken         // 복용 완료 (2시간 이내)
    case todayTakenDelayed  // 복용 완료 (2시간 초과)
    case todayDelayed       // 아직 안 먹음 (2시간 초과)
    
    // 미래/휴약
    case scheduled          // 예정
    case rest               // 휴약기
}
```

**효과**
- 사용자의 복용 패턴을 정밀하게 추적
- 상태별 맞춤 피드백 제공 가능 (예: "2시간 초과! 빨리 복용하세요")
- 타입 안전성 확보로 버그 방지
- 28일 캘린더 그리드에서 직관적인 색상 매핑 가능

### 2. 앱-위젯 간 데이터 공유

**문제 상황**

위젯에서 앱의 복용 데이터를 실시간으로 표시해야 하지만, 기본적으로 앱과 위젯은 별도의 샌드박스 환경에서 동작합니다.

**해결 방법**

App Groups와 Shared CoreData Container를 구현했습니다.

```swift
// SharedCoreDataManager
final class SharedCoreDataManager {
    static let shared = SharedCoreDataManager()

    private let appGroupIdentifier = "group.app.Pilltastic.Pilling"

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PillingApp")

        guard let storeURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("PillingApp.sqlite") else {
            fatalError("Shared container URL not found")
        }

        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }

        return container
    }()
}
```

### 3. 메시지 판단 시스템 (Rule-based Message Engine)

**시스템 개요**

사용자의 복용 상태에 따라 적절한 피드백 메시지를 제공하기 위해 우선순위 기반 규칙 엔진을 구현했습니다.

**동작 흐름**

```
CalculateDashboardMessageUseCase
  └→ CalculateMessageUseCase
      ├→ buildContext (오늘/어제 상태, 연속 누락 일수 계산)
      │   ├→ findTodayRecord
      │   ├→ PillStatusFactory.createStatus
      │   └→ calculateConsecutiveMissedDays
      └→ MessageRuleEngine.evaluate
          └→ 우선순위 순으로 Rule 평가 → MessageType 반환
```

**MessageRule 우선순위 (낮을수록 먼저 평가)**

| 우선순위 | Rule | 조건 | 반환 메시지 |
|---------|------|------|-----------|
| 10 | EarlyTakingRule | 예정 시간 2시간 전에 복용 | "너무 일찍 복용함" |
| 75 | RestDayRule | 오늘이 휴약기 | "휴식 중" |
| 100 | ConsecutiveMissedRule | 2일 이상 연속 누락 | "화난 필링" |
| 200 | RecentlyMissedRule | 어제 누락 | "어제 깜빡했니?" |
| 300 | DoubleDosingRule | 어제 누락 + 오늘 2알 가능 | "오늘 2알 복용" |
| 400 | YesterdayMissedRule | 어제 누락 + 오늘 이미 복용 | "1알 더 필요" |
| 500 | TimeBasedRule | **Fallback Rule** | 시간대별 기본 메시지 |

**핵심 컴포넌트**

1. **PillStatusFactory**: DB의 `DayRecord` → `PillStatusModel` 변환
   - `TimeContext` (과거/현재/미래) 결정
   - `MedicalTiming` (정시/지연/누락 등) 계산
   - `isRestDay` 플래그로 휴약기 판단

2. **MessageContext**: Rule 평가에 필요한 모든 정보 제공
   - `todayStatus`, `yesterdayStatus`
   - `consecutiveMissedDays`
   - `canTakeDoubleToday`

3. **MessageRuleEngine**: 우선순위 순으로 Rule을 순회하며 첫 매치를 반환
   - 모든 Rule이 실패하면 `.empty` 반환

**주의사항 **

⚠️ **문제 발생 시 확인 포인트**

1. `context.todayStatus == nil` → `findTodayRecord`가 오늘 레코드를 찾지 못함
   - TimeProvider의 `isDate(_:inSameDayAs:)` 로직 확인
   - DB에 저장된 `scheduledDateTime`의 타임존 확인

2. `MessageType.empty` 반환 → 모든 Rule이 매치 실패
   - `TimeBasedRule`은 fallback이므로 반드시 매치되어야 함
   - `todayStatus == nil`일 가능성 높음

3. 휴약기인데 다른 메시지 출력 → `RestDayRule` 우선순위 확인
   - `record.status == .rest` vs `PillStatusFactory`의 `isRestDay` 플래그 불일치

4. 연속 누락 계산 오류 → `calculateConsecutiveMissedDays` 로직
   - 오늘은 제외하고 어제부터 역순으로 계산
   - `TimeThreshold.fullyMissed` (24시간) 기준

**디버깅 코드 위치**

```swift
// CalculateMessageUseCase.swift:52-57, 98-103
// MessageRuleEngine.swift:11-28
// 디버그 로그를 통해 각 단계별 상태 추적 가능
```

**MessageType 매핑표**

개발자 참고용: 각 MessageType의 의미와 사용처를 한눈에 파악할 수 있습니다.

| MessageType | 카테고리 | 한글 메시지 | 영문 메시지 | 사용 Rule |
|------------|---------|-----------|-----------|----------|
| **시스템 메시지** | | | | |
| `.empty` | 시스템 | "약을 설정해주세요" | "Please set up your pill" | CalculateMessageUseCase |
| `.beforeStart(Int)` | 시스템 | "N일 후 시작" | "Start in N days" | CalculateMessageUseCase |
| `.cycleComplete` | 시스템 | "새 약을 설정해주세요" | "Please set up a new pill" | CalculateMessageUseCase |
| `.resting` | 시스템 | "오늘은 잔디도 휴식중" | "Even the grass is resting today" | RestDayRule |
| **복용 완료 상태** | | | | |
| `.takenToday` | 상태 | "잔디가 잘 자라요" | "The grass is growing well" | TimeBasedRule |
| `.timeTakenDelayed` | 상태 | "괜찮아요, 2시간만 지났어요" | "It's okay, just 2 hours late!" | TimeBasedRule |
| `.takenTooEarly` | 상태 | "예정보다 2시간 이상 일찍 복용했어요" | "You took it more than 2 hours early" | EarlyTakingRule |
| `.doubleDoseDoneToday` | 상태 | "오늘 2알 완료! 잘하고 있어요" | "2 pills done! You're doing great" | DoubleDosingRule |
| `.takenSuccess` | 상태 | "꾸준히 잔디를 심어요" | "Keep planting consistently" | - |
| **시간대 메시지** | | | | |
| `.timeOnTimeNotTaken` | 시간 | "오늘 잔디를 심어요" | "Plant today's grass" | TimeBasedRule |
| `.overTwoHours` | 시간 | "2시간 지났어요" | "Over 2 hours" | TimeBasedRule |
| `.overFourHours` | 시간 | "4시간 지났어요" | "Over 4 hours" | TimeBasedRule |
| **어제 누락 경고** | | | | |
| `.missedYesterdayTakeTwo` | 경고 | "어제 미복용했다면 오늘은 2알!!" | "Missed yesterday? Take two today!" | DoubleDosingRule |
| `.missedYesterdayNeedOneMore` | 경고 | "한알 더 먹어야해요!" | "You need one more pill!" | YesterdayMissedRule |
| `.missedYesterdayTwoPillsDoneLate` | 경고 | "매일 같은 시간에 2시간 이내 복용하세요" | "Take within 2 hours" | RecentlyMissedRule |
| **연속 누락 경고** | | | | |
| `.missedOneDay` | 경고 | "필링이가 찾아요..." | "Pilling is looking for you..." | - |
| `.consecutiveMissed(Int)` | 경고 | "N일째 기록이 없어요. 괜찮으신가요?" | "No record for N days. Everything okay?" | ConsecutiveMissedRule |
| `.missedThreePlusDays` | 경고 | "나를 잊으셨나요...?" | "Did you forget me...?" | ConsecutiveMissedRule |

### 4. 의료 규칙 기반 단위 테스트

**문제**

피임약 복용 로직은 의학적 안전성과 직결되며, ±2시간 허용 범위, 1일 누락 시 2알 복용, 2일 연속 누락 시 추가 피임법 필요 등 복약 지도 규칙을 정확히 반영해야 합니다. 그러나 초기 개발 중 다음과 같은 문제들을 발견했습니다:

- "어제 09:00 예정이었는데 오늘 06:30에 복용하면 '너무 일찍 복용함'이 아니라 '한 알 더 필요해요'가 나온다" (우선순위 충돌)
- "scheduled + 정확히 2시간" 같은 경계값 검증이 테스트 실행 시각에 따라 결과가 달라져 재현 불가
- 타임존 변경(GMT → KST)이나 자정 경계 케이스를 테스트하려면 시스템 시간을 조작해야 하는데 CI/CD 환경에서 불가능
- 휴약기 전환을 검증하려면 실제로 21일을 기다려야 함

**접근**

시간 정보를 제공하는 기능을 `TimeProvider` 프로토콜로 분리하고, 프로덕션에서는 `RealTimeProvider`, 테스트에서는 `MockTimeProvider`를 주입하도록 구성했습니다.

```swift
protocol TimeProvider {
    var now: Date { get }
    var calendar: Calendar { get }
    var timeZone: TimeZone { get }
    func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool
}

// 테스트용 Mock
class MockTimeProvider: TimeProvider {
    var now: Date = Date()
    var calendar: Calendar = Calendar.current
    var timeZone: TimeZone = TimeZone.current

    // 원하는 시각으로 고정 가능
    func setNow(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) {
        now = calendar.date(from: DateComponents(
            year: year, month: month, day: day,
            hour: hour, minute: minute
        ))!
    }
}
```

피임약 복약 지도 규칙을 **7개 카테고리, 39개 단위 테스트**로 분류하여 검증했습니다:

1. **복용 시간 규칙** (6개): scheduled ± 2시간 경계, 너무 이른 복용, 12시간 이상 지연
2. **누락 복용 보상** (5개): 어제 missed + 오늘 미복용/1알/2알 복용 조합
3. **연속 미복용** (4개): 1일/2일/3일+ 누락 시 메시지 강도 단계
4. **사이클 전환** (6개): 21일차 → 휴약기, 휴약 7일 → 새 사이클
5. **휴약기 처리** (4개): 휴약일 메시지, 휴약기 복용 시도
6. **2알 복용 시나리오** (4개): 정상 상태에서 2알, 어제 누락 후 2알
7. **우선순위 규칙** (10개): 여러 조건 동시 충족 시 올바른 메시지 반환

**대표 테스트 케이스**

**1) ±2시간 경계값 검증** (피임 효과 유지 기준점)

```swift
func test_허용범위_경계_정시복용() {
    // Given: 09:00 예정, 10:59 복용 (scheduled + 1시간 59분)
    let scheduledDate = calendar.date(from: DateComponents(
        year: 2024, month: 1, day: 10, hour: 9
    ))!
    let takenAt = calendar.date(from: DateComponents(
        year: 2024, month: 1, day: 10, hour: 10, minute: 59
    ))!

    // When: 상태 평가
    mockTimeProvider.now = takenAt
    let status = statusFactory.createStatus(
        scheduledDate: scheduledDate,
        actionDate: takenAt,
        evaluationDate: takenAt,
        isRestDay: false
    )

    // Then: 정상 복용으로 판단
    XCTAssertEqual(status.medicalTiming, .onTime)
}

func test_허용범위_초과_지연복용() {
    // Given: 09:00 예정, 11:01 복용 (scheduled + 2시간 1분)
    let takenAt = calendar.date(from: DateComponents(
        year: 2024, month: 1, day: 10, hour: 11, minute: 1
    ))!

    // When/Then: 지연 복용으로 판단
    XCTAssertEqual(status.medicalTiming, .delayed)
}
```

**2) 1일 누락 보상 시나리오** (복약 지도: 깨닫는 즉시 1알 + 원래 시간 1알)

```swift
func test_어제놓침_오늘1알복용_1알더필요_메시지() {
    // Given: 어제(01-09) missed, 오늘(01-10) 1알만 복용
    let yesterdayRecord = createRecord(
        scheduledDate: "2024-01-09 09:00",
        status: .missed
    )
    let todayRecord = createRecord(
        scheduledDate: "2024-01-10 09:00",
        status: .taken,
        takenAt: "2024-01-10 09:10"
    )

    // When: 메시지 계산
    mockTimeProvider.now = "2024-01-10 09:10"
    let result = calculateMessageUseCase.execute(cycle: cycle, for: now)

    // Then: 1알 더 복용 권유
    XCTAssertEqual(result.text, "한 알 더 필요해요!")
}
```

**3) 연속 누락 경고 단계** (의학적 위험도에 따른 메시지 강도)

```swift
func test_연속2일미복용_Fire_메시지_반환() {
    // Given: 01-08, 01-09 missed, 01-10 미복용
    let records = [
        createRecord(scheduledDate: "2024-01-08 09:00", status: .missed),
        createRecord(scheduledDate: "2024-01-09 09:00", status: .missed),
        createRecord(scheduledDate: "2024-01-10 09:00", status: .notTaken)
    ]

    // When/Then: 긴급 메시지 (2일째 기록 없음)
    XCTAssertEqual(result.text, MessageType.fire(days: 2).text)
}
```

**결과**

테스트 커버리지가 **48% → 68%**로 향상되었고, **우선순위 규칙 충돌 버그 3건**을 발견해 수정했습니다:

1. **EarlyTakingRule vs YesterdayMissedRule 충돌**
   - 문제: "어제 누락 + 오늘 이른 시각 복용"일 때 "너무 일찍 복용함" 메시지 표시
   - 해결: `EarlyTakingRule`에 `yesterdayNotMissed` 조건 추가하여 우선순위 400번 Rule이 먼저 평가되도록 수정

2. **연속 미복용 계산 오류**
   - 문제: DB에 `.missed` 상태로 저장된 레코드를 시간 경과로만 판단하여 "어제 09:00 missed + 오늘 06:30 복용"일 때 연속 미복용 0일로 계산
   - 해결: `calculateConsecutiveMissedDays`를 수정해 DB 상태를 우선 확인하고 그 다음 시간 경과 판단

3. **ConsecutiveMissedRule 조건 오류**
   - 문제: 1일 누락도 "화난 필링" 메시지 표시 (의도: 2일 이상만)
   - 해결: `consecutiveMissedDays > 0`을 `>= 2`로 수정

**TimeProvider 도입 전후 비교:**

| 항목 | 도입 전 | 도입 후 |
|-----|--------|---------|
| 경계값 테스트 | 실제 시각 맞춰 실행 필요 (scheduled + 2시간 = 11:00까지 대기) | 1초 만에 자동 검증 |
| 휴약기 전환 | 21일 기다려야 검증 가능 | 즉시 검증 가능 |
| 버그 수정 시간 | 평균 30분 (재현 어려움) | 평균 5분 (즉시 재현) |
| CI/CD | 타임존/시각 제어 불가 | 완전 제어 가능 |

**테스트 파일 위치:**
- [CalculateMessageUseCaseTests.swift](PillingAppTests/UseCase/CalculateMessageUseCaseTests.swift) - 메시지 판단 로직 테스트 (22개)
- [PillStatusFactoryTests.swift](PillingAppTests/Factory/PillStatusFactoryTests.swift) - 상태 계산 로직 테스트 (17개)

**향후 개선:**
- 타임존 변경 케이스 추가 (해외 여행 시나리오)
- 일광절약시간 전환 케이스 추가
- 사이클 시작 후 첫 7일 "안정화 기간" 특수 처리 테스트

---

## 리팩토링 성과

### 기술 스택 전환

| 항목 | Before (팀 프로젝트) | After (개인 리팩토링) | 이유 |
|------|---------------------|----------------------|------|
| UI | SwiftUI | UIKit + SnapKit | iOS 16 API 제약, 세밀한 레이아웃 제어 |
| 데이터베이스 | SwiftData | CoreData | iOS 16 지원, 안정성 확보 |
| 알림 | LiveActivity | WidgetKit | 사용자 접근성 개선 |

### 버전 히스토리
- **v1.0:** 팀 프로젝트 버전 
  - [v1.0 Repository 보기](https://github.com/DeveloperAcademy-POSTECH/2024-MC2-M3-Pilltastic)


### 코드 품질 개선

- Clean Architecture 적용으로 계층 간 의존성 최소화
- Protocol 기반 설계로 테스트 용이성 확보 (테스트 커버리지 60% 이상)
- RxSwift를 통한 선언적 프로그래밍 패러다임 적용
- 9개 공유 파일 Target Membership 설정으로 코드 중복 제거

---

## 회고

### 기술적 성장

- Clean Architecture와 RxSwift를 실무 수준으로 적용하며 아키텍처 설계 역량 향상
- UIKit과 SwiftUI의 장단점을 이해하고 프로젝트 요구사항에 맞는 기술 선택 능력 배양
- App Groups, CoreData, WidgetKit 등 iOS 플랫폼 고유 기술에 대한 깊은 이해

### 문제 해결

- App Groups 대소문자 이슈 등 실제 production 환경에서 발생 가능한 문제를 경험하고 해결
- SnapKit constraint 업데이트 로직 최적화를 통해 AutoLayout 메커니즘에 대한 이해도 향상

### 사용자 중심 사고

- 단순히 기능 구현을 넘어 사용자 경험을 고려한 상태 세분화 및 피드백 시스템 설계
- 위젯을 통한 즉시 접근성 제공으로 사용자 편의성 극대화

---

## 개발자

|<img alt="Piri" src="https://github.com/DeveloperAcademy-POSTECH/2024-MC2-M3-Pilltastic/assets/62399318/d390c9ff-e232-457e-8311-fa22d56097f7" width="150">|
|:---:|
|[Piri(김소람)](https://github.com/piriram)|
|iOS 개발|



---

## 라이선스

MIT License

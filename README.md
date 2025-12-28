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

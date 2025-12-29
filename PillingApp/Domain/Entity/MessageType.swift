import Foundation

/// 메시지 타입 enum
enum MessageType {

    // MARK: - 시스템 메시지

    case empty                              // 시스템: 사이클/데이터 없음
    case beforeStart(daysUntilStart: Int)   // 시스템: 시작 전 안내 (X일 전)
    case cycleComplete                      // 시스템: 사이클 완료 안내
    case resting                            // 시스템: 휴약기 안내

    // MARK: - 복용 완료 상태

    case takenOnTime                         // 상태: 오늘 정상 복용 완료
    case takenDelayed                   // 상태: 지연 복용 완료 (2시간 초과, 괜찮음)
    case takenTooEarly                      // 상태: 너무 이른 복용 (2시간 이상 빠름)
    case doubleDoseComplete                // 상태: 2알 복용 완료
    case takenConsecutive                       // 상태: 연속 정상 복용 격려

    // MARK: - 시간대 메시지

    case onTimeNotTaken                 // 시간: 복용 시간대 도달, 아직 미복용
    case overTwoHours                       // 시간: 2시간 초과 미복용
    case overFourHours                      // 시간: 4시간 초과 미복용

    // MARK: - 어제 누락 관련 경고

    case yesterdayMissedTakeTwo             // 경고: 어제 누락 → 오늘 2알 복용 권유
    case yesterdayMissedNeedOne         // 경고: 어제 누락 + 오늘 1알 복용 → 1알 더 필요
    case yesterdayMissedLateTiming    // 경고: 어제 누락 + 오늘 2알 복용 (36h 이후)

    // MARK: - 연속 누락 경고

    case missedOneDayWarning                       // 경고: 1일 누락 (가벼운 경고)
    case consecutiveMissedWarning(days: Int)       // 경고: 2일 연속 누락 (긴급)
    case missedThreePlusWarning                // 경고: 3일 이상 누락 (포기 상태)
    
    var text: String {
        switch self {
        case .empty:
            return AppStrings.Message.empty
        case .cycleComplete:
            return AppStrings.Message.cycleComplete
        case .resting:
            return AppStrings.Message.restPeriod
        case .missedThreePlusWarning:
            return AppStrings.Message.forgotMe
        case .onTimeNotTaken:
            return AppStrings.Message.plantTodayGrass
        case .takenConsecutive:
            return AppStrings.Message.plantSteadily
        case .missedOneDayWarning:
            return AppStrings.Message.pillingSearching
        case .consecutiveMissedWarning(let days):
            return AppStrings.Message.noRecordForDays(days)
        case .takenOnTime:
            return AppStrings.Message.grassGrowingWell
        case .yesterdayMissedTakeTwo:
            return AppStrings.Message.missedYesterdayTakeTwo
        case .yesterdayMissedLateTiming:
            return AppStrings.Message.takeWithinTwoHours
        case .yesterdayMissedNeedOne:
            return AppStrings.Message.needOnePillMore
        case .takenDelayed:
            return AppStrings.Message.takenDelayedOk
        case .takenTooEarly:
            return AppStrings.Message.tookTooEarly
        case .doubleDoseComplete:
            return AppStrings.Message.takeTwoPills  //
        case .beforeStart(let daysUntilStart):
            if daysUntilStart == 0 {
                return AppStrings.Message.startTakingToday
            } else if daysUntilStart == 1 {
                return AppStrings.Message.startTakingTomorrow
            } else {
                return AppStrings.Message.daysUntilStart(daysUntilStart)
            }
        case .overTwoHours:
            return AppStrings.Message.overTwoHours
        case .overFourHours:
            return AppStrings.Message.overFourHours
        }
    }
    
    var widgetText: String? {
        switch self {
        case .onTimeNotTaken:
            return AppStrings.Message.widgetPlantGrass
        case .takenOnTime:
            return AppStrings.Message.widgetPlantingComplete
        case .missedThreePlusWarning:
            return AppStrings.Message.widgetGrassWaiting
        case .missedOneDayWarning:
            return AppStrings.Message.widgetOverTwoHours
        case .consecutiveMissedWarning:
            return AppStrings.Message.widgetOverFourHours
        case .resting:
            return AppStrings.Message.widgetRestTime
        default:
            return nil
        }
    }
    
    var characterImageName: String {
        switch self {
        case .empty:
            return "icon_plant"
        case .cycleComplete:
            return "icon_rest"
        case .resting:
            return "icon_rest"
        case .missedThreePlusWarning:
            return "icon_noTaking"
        case .onTimeNotTaken:
            return "icon_takingBefore"
        case .takenConsecutive:
            return "icon_good"
        case .missedOneDayWarning:
            return "icon_2hour"
        case .consecutiveMissedWarning:
            return "icon_4hour"
        case .takenOnTime:
            return "icon_takingAfter"
        case .yesterdayMissedTakeTwo:
            return "icon_takingBeforeTwo"
        case .yesterdayMissedLateTiming:
            return "icon_takingBefore"
        case .yesterdayMissedNeedOne:
            return "icon_takingBeforeTwo"
        case .takenDelayed:
            return "icon_takingAfter"
        case .takenTooEarly:
            return "icon_takingAfter"
        case .doubleDoseComplete:
            return "icon_takingAfter" //
        case .beforeStart:
            return "icon_plant"
        case .overTwoHours:
            return "icon_2hour"
        case .overFourHours:
            return "icon_4hour"
        }
    }
    
    var iconImageName: String {
        switch self {
        case .empty, .cycleComplete, .resting:
            return "rest"
        case .missedThreePlusWarning,.consecutiveMissedWarning,.missedOneDayWarning:
            return "missed"
        case .onTimeNotTaken,.yesterdayMissedTakeTwo, .yesterdayMissedNeedOne,.overTwoHours,.overFourHours:
            return "notTaken"
        case .takenConsecutive, .takenOnTime, .yesterdayMissedLateTiming, .takenDelayed, .takenTooEarly, .doubleDoseComplete:
            return "taken"
        case .beforeStart:
            return "rest"
        }
    }
    
    var backgroundImageName: String {
        switch self {
        case .missedThreePlusWarning, .missedOneDayWarning, .consecutiveMissedWarning:
            return "background_rest"
        case .resting, .empty, .beforeStart:
            return "background_rest"
        case .cycleComplete:
            return "background_taken"
        default:
            return "background_taken"
        }
    }
    
    var widgetBackgroundImage: String {
        switch self {
        case .missedThreePlusWarning:
            return "widget_background_warning"
        case .missedOneDayWarning:
            return "widget_background_groomy"
        case .consecutiveMissedWarning:
            return "widget_background_fire"
        default:
            return "widget_background_normal"
        }
    }
    
    func toResult() -> MessageResult {
        return MessageResult(
            text: text,
            widgetText: widgetText,
            characterImageName: characterImageName,
            iconImageName: iconImageName,
            backgroundImageName: backgroundImageName
        )
    }
}

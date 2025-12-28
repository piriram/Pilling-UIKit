import Foundation

/// 메시지 타입 enum
enum MessageType {
    
    case empty                              // 사이클/데이터 없음
    case beforeStart(daysUntilStart: Int)   // 시작 전 안내
    case cycleComplete                      // 사이클 완료 안내
    
    case resting                            // 휴약일 안내
    case missedThreePlusDays                            // 연속 미복용 3일 이상 경고
    case missedOneDay                       // 연속 미복용 1일(가벼운 경고)
    case consecutiveMissed(days: Int)       // 연속 미복용 N일 (2일 이상)
    
    case timeOnTimeNotTaken                       // 오늘 복용 시간대에 아직 미복용
    case overTwoHours                       // 2시간 경과 미복용
    case overFourHours                      // 4시간 경과 미복용
    case timeTakenDelayed                     // 지연 복용(2시간 초과) 완료
    
    case missedYesterdayTakeTwo                    // 예: 어제 21:00 미복용, 오늘 09:00~+36h 내 미복용 → “오늘 2알 복용하세요”
    case missedYesterdayTwoPillsDoneLate                       // 예: 어제 21:00 미복용, 오늘 09:00에 2알 복용(36h 이후) → 추가 안내
    case missedYesterdayNeedOneMore                            // 어제 미복용 + 오늘 복용 관련 추가 경고(의미 구체화 필요)
    
    case doubleDoseDoneToday                       // 더블 복용 완료 메시지
    
    case takenTooEarly                      // 예정 시간보다 2시간 이상 일찍 복용
    case takenToday                         // 오늘 복용 완료 후 일반 안내
    case takenSuccess                            // 정상 복용/연속 복용에 대한 긍정 메시지
    
    var text: String {
        switch self {
        case .empty:
            return AppStrings.Message.empty
        case .cycleComplete:
            return AppStrings.Message.cycleComplete
        case .resting:
            return AppStrings.Message.restPeriod
        case .missedThreePlusDays:
            return AppStrings.Message.forgotMe
        case .timeOnTimeNotTaken:
            return AppStrings.Message.plantTodayGrass
        case .takenSuccess:
            return AppStrings.Message.plantSteadily
        case .missedOneDay:
            return AppStrings.Message.pillingSearching
        case .consecutiveMissed(let days):
            return AppStrings.Message.noRecordForDays(days)
        case .takenToday:
            return AppStrings.Message.grassGrowingWell
        case .missedYesterdayTakeTwo:
            return AppStrings.Message.missedYesterdayTakeTwo
        case .missedYesterdayTwoPillsDoneLate:
            return AppStrings.Message.takeWithinTwoHours
        case .missedYesterdayNeedOneMore:
            return AppStrings.Message.needOnePillMore
        case .timeTakenDelayed:
            return AppStrings.Message.takenDelayedOk
        case .takenTooEarly:
            return AppStrings.Message.tookTooEarly
        case .doubleDoseDoneToday:
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
        case .timeOnTimeNotTaken:
            return AppStrings.Message.widgetPlantGrass
        case .takenToday:
            return AppStrings.Message.widgetPlantingComplete
        case .missedThreePlusDays:
            return AppStrings.Message.widgetGrassWaiting
        case .missedOneDay:
            return AppStrings.Message.widgetOverTwoHours
        case .consecutiveMissed:
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
        case .missedThreePlusDays:
            return "icon_noTaking"
        case .timeOnTimeNotTaken:
            return "icon_takingBefore"
        case .takenSuccess:
            return "icon_good"
        case .missedOneDay:
            return "icon_2hour"
        case .consecutiveMissed:
            return "icon_4hour"
        case .takenToday:
            return "icon_takingAfter"
        case .missedYesterdayTakeTwo:
            return "icon_takingBeforeTwo"
        case .missedYesterdayTwoPillsDoneLate:
            return "icon_takingBefore"
        case .missedYesterdayNeedOneMore:
            return "icon_takingBeforeTwo"
        case .timeTakenDelayed:
            return "icon_takingAfter"
        case .takenTooEarly:
            return "icon_takingAfter"
        case .doubleDoseDoneToday:
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
        case .missedThreePlusDays,.consecutiveMissed,.missedOneDay:
            return "missed"
        case .timeOnTimeNotTaken,.missedYesterdayTakeTwo, .missedYesterdayNeedOneMore,.overTwoHours,.overFourHours:
            return "notTaken"
        case .takenSuccess, .takenToday, .missedYesterdayTwoPillsDoneLate, .timeTakenDelayed, .takenTooEarly, .doubleDoseDoneToday:
            return "taken"
        case .beforeStart:
            return "rest"
        }
    }
    
    var backgroundImageName: String {
        switch self {
        case .missedThreePlusDays, .missedOneDay, .consecutiveMissed:
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
        case .missedThreePlusDays:
            return "widget_background_warning"
        case .missedOneDay:
            return "widget_background_groomy"
        case .consecutiveMissed:
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

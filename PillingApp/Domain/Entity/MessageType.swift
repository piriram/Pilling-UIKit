import Foundation

/// 메시지 타입 enum
enum MessageType {
    case empty
    case cycleComplete
    case resting
    case waiting
    case plantingSeed
    case success
    case groomy
    case fire(days: Int)
    case overTwoHours
    case overFourHours
    case pilledTwo
    case morePill
    case todayAfter
    case takingBeforeTwo
    case takingBefore
    case warning
    case takenDelayedOk
    case takenTooEarly
    case takenDoubleComplete
    case beforeStart(daysUntilStart: Int)
    
    var text: String {
        switch self {
        case .empty:
            return AppStrings.Message.empty
        case .cycleComplete:
            return AppStrings.Message.cycleComplete
        case .resting:
            return AppStrings.Message.restPeriod
        case .waiting:
            return AppStrings.Message.forgotMe
        case .plantingSeed:
            return AppStrings.Message.plantTodayGrass
        case .success:
            return AppStrings.Message.plantSteadily
        case .groomy:
            return AppStrings.Message.pillingSearching
        case .fire(let days):
            return AppStrings.Message.noRecordForDays(days)
        case .pilledTwo:
            return AppStrings.Message.takeTwoPills
        case .todayAfter:
            return AppStrings.Message.grassGrowingWell
        case .takingBeforeTwo:
            return AppStrings.Message.missedYesterdayTakeTwo
        case .takingBefore:
            return AppStrings.Message.takeWithinTwoHours
        case .warning:
            return AppStrings.Message.needOnePillMore
        case .takenDelayedOk:
            return AppStrings.Message.takenDelayedOk
        case .takenTooEarly:
            return AppStrings.Message.tookTooEarly
        case .takenDoubleComplete:
            return AppStrings.Message.seeTomorrow
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
        case .morePill:
            return AppStrings.Message.onePillMore
        }
    }
    
    var widgetText: String? {
        switch self {
        case .plantingSeed:
            return AppStrings.Message.widgetPlantGrass
        case .todayAfter:
            return AppStrings.Message.widgetPlantingComplete
        case .waiting:
            return AppStrings.Message.widgetGrassWaiting
        case .groomy:
            return AppStrings.Message.widgetOverTwoHours
        case .fire:
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
        case .waiting:
            return "icon_noTaking"
        case .plantingSeed:
            return "icon_takingBefore"
        case .success:
            return "icon_good"
        case .groomy:
            return "icon_2hour"
        case .fire:
            return "icon_4hour"
        case .pilledTwo:
            return "icon_takingBeforeTwo"
        case .todayAfter:
            return "icon_takingAfter"
        case .takingBeforeTwo:
            return "icon_takingBeforeTwo"
        case .takingBefore:
            return "icon_takingBefore"
        case .warning:
            return "icon_takingBeforeTwo"
        case .takenDelayedOk:
            return "icon_takingAfter"
        case .takenTooEarly:
            return "icon_takingAfter"
        case .takenDoubleComplete:
            return "icon_takingAfter"
        case .beforeStart:
            return "icon_plant"
        case .overTwoHours:
            return "icon_2hour"
        case .overFourHours:
            return "icon_4hour"
        case .morePill:
            return "icon_takingBeforeTwo"
        }
    }
    
    var iconImageName: String {
        switch self {
        case .empty, .cycleComplete, .resting:
            return "rest"
        case .waiting,.fire,.groomy:
            return "missed"
        case .plantingSeed, .pilledTwo, .takingBeforeTwo, .warning,.overTwoHours,.overFourHours:
            return "notTaken"
        case .success, .todayAfter, .takingBefore, .takenDelayedOk, .takenTooEarly, .takenDoubleComplete,.morePill:
            return "taken"
        case .beforeStart:
            return "rest"
        }
    }
    
    var backgroundImageName: String {
        switch self {
        case .waiting, .groomy, .fire:
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
        case .waiting:
            return "widget_background_warning"
        case .groomy:
            return "widget_background_groomy"
        case .fire:
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

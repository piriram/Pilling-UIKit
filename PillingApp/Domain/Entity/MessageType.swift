import Foundation

/// 메시지 타입 enum
enum MessageType {

    // MARK: - 시스템 메시지

    case empty                              // 시스템: 사이클/데이터 없음
    case beforeStart(daysUntilStart: Int)   // 시스템: 시작 전 안내 (X일 전)
    case cycleComplete                      // 시스템: 사이클 완료 안내
    case resting                            // 시스템: 휴약기 안내

    // MARK: - 복용 완료 상태

    case takenComplete(timing: MedicalTiming, minutesDiff: Int?)  // 상태: 복용 완료 (정시/지연/일찍)
    case doubleDoseComplete                                        // 상태: 2알 복용 완료

    // MARK: - 미복용 상태

    case notTakenYet(timing: MedicalTiming)  // 시간: 아직 미복용 (정시/2시간/4시간 초과)

    // MARK: - 어제 누락 관련 경고

    case yesterdayMissedTakeTwo             // 경고: 어제 누락 → 오늘 2알 복용 권유
    case yesterdayMissedNeedOne             // 경고: 어제 누락 + 오늘 1알 복용 → 1알 더 필요
    case yesterdayMissedLateTiming          // 경고: 어제 누락 + 오늘 2알 복용 (36h 이후)

    // MARK: - 연속 누락 경고

    case consecutiveMissedWarning(days: Int)  // 경고: 2일 이상 연속 누락 (2일/3일+)

    var text: String {
        switch self {
        case .empty:
            return AppStrings.Message.empty
        case .cycleComplete:
            return AppStrings.Message.cycleComplete
        case .resting:
            return AppStrings.Message.restPeriod
        case .consecutiveMissedWarning(let days):
            if days >= 3 {
                return AppStrings.Message.forgotMe  // "저를 잊었나요...?"
            } else {
                return AppStrings.Message.noRecordForDays(days)  // "N일째 기록이 없어요"
            }
        case .notTakenYet(let timing):
            switch timing {
            case .onTime, .upcoming:
                return AppStrings.Message.plantTodayGrass  // "오늘의 잔디를 심어주세요"
            case .slightDelay:
                return AppStrings.Message.overTwoHours     // "2시간 지났어요"
            case .moderate:
                return AppStrings.Message.overFourHours    // "4시간 지났어요"
            case .recent, .missed:
                return AppStrings.Message.forgotMe         // "저를 잊었나요...?"
            default:
                return AppStrings.Message.plantTodayGrass
            }
        case .takenComplete(let timing, let minutesDiff):
            switch timing {
            case .onTime:
                return AppStrings.Message.grassGrowingWell  // "잔디가 잘 자라고 있어요"
            case .slightDelay:
                return AppStrings.Message.takenDelayedOk    // "2시간 지났지만 괜찮아요!"
            case .tooEarly:
                if let minutes = minutesDiff {
                    let absMinutes = abs(minutes)
                    let hours = absMinutes / 60
                    let mins = absMinutes % 60
                    if hours > 0 && mins > 0 {
                        return "예정보다 \(hours)시간 \(mins)분 일찍 복용했어요"
                    } else if hours > 0 {
                        return "예정보다 \(hours)시간 일찍 복용했어요"
                    } else {
                        return "예정보다 \(mins)분 일찍 복용했어요"
                    }
                }
                return AppStrings.Message.tookTooEarly
            default:
                return AppStrings.Message.grassGrowingWell
            }
        case .yesterdayMissedTakeTwo:
            return AppStrings.Message.missedYesterdayTakeTwo
        case .yesterdayMissedLateTiming:
            return AppStrings.Message.takeWithinTwoHours
        case .yesterdayMissedNeedOne:
            return AppStrings.Message.needOnePillMore
        case .doubleDoseComplete:
            return AppStrings.Message.takeTwoPills
        case .beforeStart(let daysUntilStart):
            if daysUntilStart == 0 {
                return AppStrings.Message.startTakingToday
            } else if daysUntilStart == 1 {
                return AppStrings.Message.startTakingTomorrow
            } else {
                return AppStrings.Message.daysUntilStart(daysUntilStart)
            }
        }
    }

    var widgetText: String? {
        switch self {
        case .notTakenYet(let timing):
            switch timing {
            case .onTime, .upcoming:
                return AppStrings.Message.widgetPlantGrass
            case .slightDelay:
                return AppStrings.Message.widgetOverTwoHours
            case .moderate, .recent, .missed:
                return AppStrings.Message.widgetOverFourHours
            default:
                return nil
            }
        case .takenComplete:
            return AppStrings.Message.widgetPlantingComplete
        case .consecutiveMissedWarning(let days):
            if days >= 3 {
                return AppStrings.Message.widgetGrassWaiting
            } else {
                return AppStrings.Message.widgetOverFourHours
            }
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
        case .consecutiveMissedWarning(let days):
            if days >= 3 {
                return "icon_noTaking"
            } else {
                return "icon_4hour"
            }
        case .notTakenYet(let timing):
            switch timing {
            case .onTime, .upcoming:
                return "icon_takingBefore"
            case .slightDelay:
                return "icon_2hour"
            case .moderate, .recent, .missed:
                return "icon_4hour"
            default:
                return "icon_takingBefore"
            }
        case .takenComplete:
            return "icon_takingAfter"
        case .yesterdayMissedTakeTwo:
            return "icon_takingBeforeTwo"
        case .yesterdayMissedLateTiming:
            return "icon_takingBefore"
        case .yesterdayMissedNeedOne:
            return "icon_takingBeforeTwo"
        case .doubleDoseComplete:
            return "icon_takingAfter"
        case .beforeStart:
            return "icon_plant"
        }
    }

    var iconImageName: String {
        switch self {
        case .empty, .cycleComplete, .resting:
            return "rest"
        case .consecutiveMissedWarning:
            return "missed"
        case .notTakenYet, .yesterdayMissedTakeTwo, .yesterdayMissedNeedOne:
            return "notTaken"
        case .takenComplete, .yesterdayMissedLateTiming, .doubleDoseComplete:
            return "taken"
        case .beforeStart:
            return "rest"
        }
    }

    var backgroundImageName: String {
        switch self {
        case .consecutiveMissedWarning:
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
        case .consecutiveMissedWarning(let days):
            if days >= 3 {
                return "widget_background_warning"
            } else {
                return "widget_background_fire"
            }
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

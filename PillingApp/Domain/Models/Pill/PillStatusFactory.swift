import Foundation

final class PillStatusFactory {
    private let timeProvider: TimeProvider

    init(timeProvider: TimeProvider) {
        self.timeProvider = timeProvider
    }

    func createStatus(
        scheduledDate: Date,
        actionDate: Date? = nil,
        evaluationDate: Date = Date(),
        isRestDay: Bool = false
    ) -> PillStatusModel {

        let timeContext = determineTimeContext(
            scheduledDate: scheduledDate,
            evaluationDate: evaluationDate
        )

        if isRestDay {
            return PillStatusModel(
                baseStatus: PillStatus.rest,
                timeContext: timeContext,
                medicalTiming: MedicalTiming.onTime,
                scheduledDate: scheduledDate,
                actionDate: actionDate
            )
        }

        let timeElapsed = evaluationDate.timeIntervalSince(scheduledDate)
        let medicalTiming = determineMedicalTiming(timeElapsed: timeElapsed)

        let baseStatus = determineBaseStatus(
            medicalTiming: medicalTiming,
            actionDate: actionDate,
            scheduledDate: scheduledDate
        )

        return PillStatusModel(
            baseStatus: baseStatus,
            timeContext: timeContext,
            medicalTiming: medicalTiming,
            scheduledDate: scheduledDate,
            actionDate: actionDate
        )
    }

    private func determineTimeContext(scheduledDate: Date, evaluationDate: Date) -> TimeContext {
        let scheduledDay = timeProvider.startOfDay(for: scheduledDate)
        let today = timeProvider.startOfDay(for: evaluationDate)

        if scheduledDay < today { return TimeContext.past }
        if scheduledDay > today { return TimeContext.future }
        return TimeContext.present
    }

    private func determineMedicalTiming(timeElapsed: TimeInterval) -> MedicalTiming {
        switch timeElapsed {
        case ..<TimeThreshold.tooEarly:
            return MedicalTiming.tooEarly
        case TimeThreshold.tooEarly..<0:
            return MedicalTiming.upcoming
        case 0..<TimeThreshold.normal:
            return MedicalTiming.onTime
        case TimeThreshold.normal..<TimeThreshold.delayed:
            return MedicalTiming.slightDelay
        case TimeThreshold.delayed..<TimeThreshold.critical:
            return MedicalTiming.moderate
        case TimeThreshold.critical..<TimeThreshold.fullyMissed:
            return MedicalTiming.recent
        default:
            return MedicalTiming.missed
        }
    }

    private func determineBaseStatus(
        medicalTiming: MedicalTiming,
        actionDate: Date?,
        scheduledDate: Date
    ) -> PillStatus {

        if let actionDate = actionDate {
            let actionTimeDiff = actionDate.timeIntervalSince(scheduledDate)

            if actionTimeDiff < TimeThreshold.tooEarly {
                return PillStatus.takenTooEarly
            } else if abs(actionTimeDiff) <= TimeThreshold.normal {
                return PillStatus.taken
            } else {
                return PillStatus.takenDelayed
            }
        }

        switch medicalTiming {
        case .tooEarly, .upcoming:
            return PillStatus.scheduled
        case .onTime, .slightDelay, .moderate:
            return PillStatus.notTaken
        case .recent:
            return PillStatus.recentlyMissed
        case .missed:
            return PillStatus.missed
        }
    }
}

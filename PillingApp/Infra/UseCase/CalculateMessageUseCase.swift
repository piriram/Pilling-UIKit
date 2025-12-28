import Foundation

final class CalculateMessageUseCase {
    private let statusFactory: PillStatusFactory
    private let ruleEngine: MessageRuleEngine
    private let timeProvider: TimeProvider

    init(statusFactory: PillStatusFactory, timeProvider: TimeProvider) {
        self.statusFactory = statusFactory
        self.timeProvider = timeProvider

        let rules: [MessageRule] = [
            EarlyTakingRule(),
            RestDayRule(),
            ConsecutiveMissedRule(),
            RecentlyMissedRule(),
            DoubleDosingRule(),
            YesterdayMissedRule(),
            TimeBasedRule()
        ]

        self.ruleEngine = MessageRuleEngine(rules: rules)
    }

    func execute(cycle: Cycle?, for date: Date = Date()) -> MessageResult {
        guard let cycle = cycle else {
            return MessageType.empty.toResult()
        }

        if date < cycle.startDate {
            return makeBeforeStartMessage(startDate: cycle.startDate, currentDate: date)
        }

        let totalDays = cycle.activeDays + cycle.breakDays
        let daysSinceStart = timeProvider.calendar.dateComponents([.day], from: cycle.startDate, to: date).day ?? 0
        let currentCycleDay = daysSinceStart + 1

        if currentCycleDay >= totalDays {
            return MessageType.cycleComplete.toResult()
        }

        let context = buildContext(cycle: cycle, date: date)
        let messageType = ruleEngine.evaluate(context: context)

        print("🔍🔍🔍🔍🔍🔍 [CalculateMessage] Final MessageType: \(messageType)")
        print("🔍 [CalculateMessage] Message text: \(messageType.text)")

        return messageType.toResult()
    }

    private func buildContext(cycle: Cycle, date: Date) -> MessageContext {
        let todayRecord = findTodayRecord(in: cycle, from: date)
        let yesterdayRecord = findYesterdayRecord(in: cycle, from: date)

        print("🔍 [CalculateMessage] buildContext - date: \(date)")
        print("🔍 [CalculateMessage] todayRecord found: \(todayRecord != nil)")
        if let record = todayRecord {
            print("🔍 [CalculateMessage] todayRecord.scheduledDateTime: \(record.scheduledDateTime)")
            print("🔍 [CalculateMessage] todayRecord.status: \(record.status)")
        }

        let todayStatus = todayRecord.map { record in
            var status = statusFactory.createStatus(
                scheduledDate: record.scheduledDateTime,
                actionDate: record.takenAt,
                evaluationDate: date,
                isRestDay: record.status == .rest
            )

            // DB에 명시적으로 저장된 특수 상태를 우선 적용
            let needsDbOverride = (record.status == .notTaken && status.baseStatus == .scheduled) ||
                                  (record.status == .takenDouble && status.baseStatus != .takenDouble)

            if needsDbOverride {
                status = PillStatusModel(
                    baseStatus: record.status,
                    timeContext: status.timeContext,
                    medicalTiming: status.medicalTiming,
                    scheduledDate: status.scheduledDate,
                    actionDate: status.actionDate
                )
            }

            return status
        }

        let yesterdayStatus = yesterdayRecord.map { record in
            statusFactory.createStatus(
                scheduledDate: record.scheduledDateTime,
                actionDate: record.takenAt,
                evaluationDate: date,
                isRestDay: record.status == .rest
            )
        }

        let consecutiveMissed = calculateConsecutiveMissedDays(
            cycle: cycle,
            upTo: date
        )

        print("🔍 [CalculateMessage] todayStatus: \(String(describing: todayStatus))")
        if let status = todayStatus {
            print("🔍 [CalculateMessage] todayStatus.baseStatus: \(status.baseStatus)")
            print("🔍 [CalculateMessage] todayStatus.timeContext: \(status.timeContext)")
            print("🔍 [CalculateMessage] todayStatus.medicalTiming: \(status.medicalTiming)")
        }

        print("🔍 [CalculateMessage] yesterdayRecord found: \(yesterdayRecord != nil)")
        if let record = yesterdayRecord {
            print("🔍 [CalculateMessage] yesterdayRecord.scheduledDateTime: \(record.scheduledDateTime)")
            print("🔍 [CalculateMessage] yesterdayRecord.status: \(record.status)")
        }
        print("🔍 [CalculateMessage] yesterdayStatus: \(String(describing: yesterdayStatus))")
        if let status = yesterdayStatus {
            print("🔍 [CalculateMessage] yesterdayStatus.baseStatus: \(status.baseStatus)")
        }

        return MessageContext(
            todayStatus: todayStatus,
            yesterdayStatus: yesterdayStatus,
            cycle: cycle,
            currentDate: date,
            consecutiveMissedDays: consecutiveMissed,
            timeProvider: timeProvider
        )
    }

    private func findTodayRecord(in cycle: Cycle, from date: Date) -> DayRecord? {
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: date)
        }
    }

    private func findYesterdayRecord(in cycle: Cycle, from date: Date) -> DayRecord? {
        guard let yesterday = timeProvider.date(byAdding: .day, value: -1, to: date) else {
            return nil
        }
        return cycle.records.first { record in
            timeProvider.isDate(record.scheduledDateTime, inSameDayAs: yesterday)
        }
    }

    private func calculateConsecutiveMissedDays(cycle: Cycle, upTo targetDate: Date) -> Int {
        var count = 0

        let sortedRecords = cycle.records.sorted {
            $0.scheduledDateTime > $1.scheduledDateTime
        }

        print("🔍 [calculateConsecutiveMissed] Starting calculation")

        // 오늘 제외하고 어제부터 계산
        var skipToday = true

        for record in sortedRecords {
            let isToday = timeProvider.isDate(record.scheduledDateTime, inSameDayAs: targetDate)

            // 오늘 레코드는 건너뛰기
            if skipToday && isToday {
                print("🔍 [calculateConsecutiveMissed] Skipping today: \(record.scheduledDateTime), status: \(record.status)")
                continue
            }
            skipToday = false

//            print("🔍 [calculateConsecutiveMissed] Checking record: \(record.scheduledDateTime), status: \(record.status), count: \(count)")

            // DB에 명시적으로 missed 상태로 저장된 경우 즉시 카운트
            if record.status == .missed {
                count += 1
                print("🔍 [calculateConsecutiveMissed] Counted missed, new count: \(count)")
                continue
            }

            // 복용한 경우 중단
            if record.status.isTaken {
                print("🔍 [calculateConsecutiveMissed] Found taken, breaking. Final count: \(count)")
                break
            }

            // 그 외의 경우 시간 경과로 판단
            let timeElapsed = targetDate.timeIntervalSince(record.scheduledDateTime)
            if timeElapsed >= TimeThreshold.fullyMissed {
                count += 1
                print("🔍 [calculateConsecutiveMissed] Counted by time elapsed, new count: \(count)")
            }
        }

        print("🔍 [calculateConsecutiveMissed] Final count: \(count)")
        return count
    }

    private func makeBeforeStartMessage(startDate: Date, currentDate: Date) -> MessageResult {
        let components = timeProvider.calendar.dateComponents([.day], from: currentDate, to: startDate)

        guard let daysUntilStart = components.day else {
            return MessageType.beforeStart(daysUntilStart: 0).toResult()
        }

        return MessageType.beforeStart(daysUntilStart: daysUntilStart).toResult()
    }
}

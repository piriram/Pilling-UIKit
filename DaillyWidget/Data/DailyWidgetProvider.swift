import WidgetKit

// MARK: - PillingDailyWidgetProvider

struct DailyWidgetProvider: TimelineProvider {

    private let coreDataManager = SharedCoreDataManager.shared
    
    // MARK: - TimelineProvider
    
    func placeholder(in context: Context) -> DailyWidgetEntry {
        return .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DailyWidgetEntry) -> Void) {
        guard let cycle = coreDataManager.fetchCurrentCycle() else {
            completion(.empty)
            return
        }
        
        let entry = createEntry(for: Date(), cycle: cycle)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyWidgetEntry>) -> Void) {
        var entries: [DailyWidgetEntry] = []
        let calendar = Calendar.current
        let now = Date()
        
        guard let cycle = coreDataManager.fetchCurrentCycle() else {
            entries.append(.empty)
            let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
            completion(timeline)
            return
        }
        
        // 오늘부터 7일치 Entry 생성
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: now)) else {
                continue
            }
            
            // 해당 날짜의 복용 예정 시간 찾기
            if let scheduledTime = getScheduledTime(for: targetDate, cycle: cycle, calendar: calendar) {
                
                // Entry 1: 복용 예정 시간 (정시)
                let scheduledEntry = createEntry(for: scheduledTime, cycle: cycle)
                entries.append(scheduledEntry)
                
                // Entry 2: 2시간 후 (딜레이 경고)
                if let delayedTime = calendar.date(byAdding: .hour, value: 2, to: scheduledTime) {
                    let delayedEntry = createEntry(for: delayedTime, cycle: cycle)
                    entries.append(delayedEntry)
                }
                
                // Entry 3: 4시간 후 (심각한 딜레이 경고)
                if let criticalDelayedTime = calendar.date(byAdding: .hour, value: 4, to: scheduledTime) {
                    let criticalEntry = createEntry(for: criticalDelayedTime, cycle: cycle)
                    entries.append(criticalEntry)
                }
                
                // Entry 4: 12시간 후 (missed, 2알 복용 안내)
                if let missedTime = calendar.date(byAdding: .hour, value: 12, to: scheduledTime) {
                    let missedEntry = createEntry(for: missedTime, cycle: cycle)
                    entries.append(missedEntry)
                }
            } else {
                // 복용 시간이 없으면 (휴약일 등) 하루에 한 번만
                let entry = createEntry(for: targetDate, cycle: cycle)
                entries.append(entry)
            }
        }
        
        // Entry가 없으면 기본값
        if entries.isEmpty {
            entries.append(.empty)
        }
        
        // Entry를 날짜순으로 정렬
        entries.sort { $0.date < $1.date }
        
        // 7일 후에 다시 업데이트
        let nextUpdate = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // MARK: - Private Methods
    
    private func getScheduledTime(for date: Date, cycle: Cycle, calendar: Calendar) -> Date? {
        // 해당 날짜의 레코드 찾기
        guard let record = cycle.records.first(where: { record in
            calendar.isDate(record.scheduledDateTime, inSameDayAs: date)
        }) else {
            return nil
        }
        
        // rest 상태면 복용 시간 없음
        if case .rest = record.status {
            return nil
        }
        
        return record.scheduledDateTime
    }
    
    private func createEntry(for date: Date, cycle: Cycle) -> DailyWidgetEntry {
        let timeProvider = SystemTimeProvider()
        let statusFactory = PillStatusFactory(timeProvider: timeProvider)
        let calculateMessageUseCase = CalculateMessageUseCase(
            statusFactory: statusFactory,
            timeProvider: timeProvider
        )

        let messageResult = calculateMessageUseCase.execute(cycle: cycle, for: date)
        let cycleDay = calculateCycleDay(from: cycle, for: date)

        let displayData = WidgetDisplayData(
            cycleDay: cycleDay,
            message: messageResult.widgetText ?? messageResult.text,
            iconImageName: messageResult.characterImageName,
            backgroundImageName: messageResult.backgroundImageName
        )

        return DailyWidgetEntry(date: date, displayData: displayData)
    }
    
    private func calculateCycleDay(from cycle: Cycle, for date: Date) -> Int {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: cycle.startDate)
        let targetDate = calendar.startOfDay(for: date)
        
        guard let days = calendar.dateComponents([.day], from: startDate, to: targetDate).day else {
           print("day 없음")
            return 0
        }
        print("days:\(days)")
        return days + 1 // 1일차부터 시작
    }
}

import CoreData
import RxSwift
import WidgetKit

final class CycleRepository: CycleRepositoryProtocol {
    
    private let coreDataManager: CoreDataManager
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    
    // 주어진 날짜가 시작일과 종료일 사이인지 판별
    private func isOngoingCycle(_ cycle: Cycle, at date: Date) -> Bool {
        let calendar = Calendar.current
        let startDate = cycle.startDate
        let endDate = calendar.date(
            byAdding: .day,
            value: cycle.totalDays - 1,
            to: startDate
        ) ?? startDate
        
        return startDate <= date && date <= endDate
    }
    
    
    // MARK: - 현재 사이클 조회(DB 조회 비용 있음)
    func fetchCurrentCycle() -> Observable<Cycle?> {
        return coreDataManager
            .fetch(
                entityType: PillCycleEntity.self,
                sortDescriptors: [
                    NSSortDescriptor(key: "createdAt", ascending: false),
                    NSSortDescriptor(key: "startDate", ascending: false)
                ]
            )
            .map { [weak self] entities in
                let cycles = entities.map { $0.toDomain() }
                let now = Date()

                // 진행 중 사이클 우선
                if let ongoingCycle = cycles.first(where: {
                    self?.isOngoingCycle($0, at: now) ?? false
                }) {
                    return ongoingCycle
                }

                // 없으면 최신 사이클
                return cycles.first
            }
            .catch { error in
                DIContainer.shared.getCrashlyticsService().logError(
                    error,
                    userInfo: ["context": "fetchCurrentCycle", "repository": "CycleRepository"]
                )
                return .error(error)
            }
    }
    
    func saveCycle(_ cycle: Cycle) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.coreDataManager.viewContext
            
            // 기존 사이클이 있는지 확인
            let fetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: CoreDataEntity.cycle)
            fetchRequest.predicate = NSPredicate(format: "id == %@", cycle.id as CVarArg)
            
            do {
                let existingCycles = try context.fetch(fetchRequest)
                
                if let existingCycle = existingCycles.first {
                    // 업데이트
                    existingCycle.update(from: cycle)
                    
                    // 기존 레코드들 삭제 후 새로 추가
                    if let records = existingCycle.records {
                        existingCycle.removeFromRecords(records)
                    }
                    
                    cycle.records.forEach { record in
                        let recordEntity = PillRecordEntity.from(domain: record, context: context)
                        recordEntity.cycle = existingCycle
                    }
                } else {
                    // 새로 생성
                    _ = PillCycleEntity.from(domain: cycle, context: context)
                }
                
                try context.save()

                WidgetCenter.shared.reloadAllTimelines()

                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.saveFailed(error))
            }
            
            return Disposables.create()
        }
    }
    
    func updateRecord(_ record: DayRecord, in cycleID: UUID) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }

            let context = self.coreDataManager.viewContext

            // 사이클 찾기
            let cycleFetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: "PillCycleEntity")
            cycleFetchRequest.predicate = NSPredicate(format: "id == %@", cycleID as CVarArg)

            do {
                guard let PillCycleEntity = try context.fetch(cycleFetchRequest).first else {
                    observer.onError(CoreDataError.invalidData)
                    return Disposables.create()
                }

                // 레코드 찾기
                let recordFetchRequest: NSFetchRequest<PillRecordEntity> = NSFetchRequest(entityName: "PillRecordEntity")
                recordFetchRequest.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)

                if let recordEntity = try context.fetch(recordFetchRequest).first {
                    // 업데이트
                    recordEntity.update(from: record)
                } else {
                    // 새로 생성
                    let newRecordEntity = PillRecordEntity.from(domain: record, context: context)
                    newRecordEntity.cycle = PillCycleEntity
                }

                try context.save()

                // ⭐️ 위젯 업데이트
                WidgetCenter.shared.reloadAllTimelines()

                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.saveFailed(error))
            }

            return Disposables.create()
        }
    }

    func updateScheduledTimes(in cycleID: UUID, newTimeString: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }

            let context = self.coreDataManager.viewContext

            // 사이클 찾기
            let cycleFetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: "PillCycleEntity")
            cycleFetchRequest.predicate = NSPredicate(format: "id == %@", cycleID as CVarArg)

            do {
                guard let cycleEntity = try context.fetch(cycleFetchRequest).first else {
                    observer.onError(CoreDataError.invalidData)
                    return Disposables.create()
                }

                // 사이클의 scheduledTime 업데이트
                cycleEntity.scheduledTime = newTimeString

                // 레코드들 가져오기
                let recordsFetchRequest: NSFetchRequest<PillRecordEntity> = NSFetchRequest(entityName: "PillRecordEntity")
                recordsFetchRequest.predicate = NSPredicate(format: "cycle == %@", cycleEntity)
                let recordEntities = try context.fetch(recordsFetchRequest)

                let calendar = Calendar.current
                let now = Date()
                let todayStart = calendar.startOfDay(for: now)

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                timeFormatter.timeZone = TimeZone.current

                guard let timeDate = timeFormatter.date(from: newTimeString) else {
                    observer.onError(CoreDataError.invalidData)
                    return Disposables.create()
                }

                let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)

                // 오늘 이후의 아직 복용하지 않은 레코드들만 업데이트
                for recordEntity in recordEntities {
                    guard let scheduledDateTime = recordEntity.scheduledDateTime else { continue }

                    let recordDateStart = calendar.startOfDay(for: scheduledDateTime)

                    // 오늘 이후이고, 아직 복용하지 않은 상태인 경우만 업데이트
                    let isNotTaken = recordEntity.takenAt == nil
                    let isTodayOrFuture = recordDateStart >= todayStart

                    if isTodayOrFuture && isNotTaken {
                        let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDateTime)

                        var combined = DateComponents()
                        combined.year = dateComponents.year
                        combined.month = dateComponents.month
                        combined.day = dateComponents.day
                        combined.hour = timeComponents.hour
                        combined.minute = timeComponents.minute
                        combined.timeZone = TimeZone.current

                        if let newScheduledDateTime = calendar.date(from: combined) {
                            recordEntity.scheduledDateTime = newScheduledDateTime
                        }
                    }
                }

                try context.save()

                WidgetCenter.shared.reloadAllTimelines()

                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.saveFailed(error))
            }

            return Disposables.create()
        }
    }
    
    // MARK: - Additional Methods
    
    func deleteAllCycles() -> Observable<Void> {
        return coreDataManager.deleteAll(entityType: PillCycleEntity.self)
            .do(onNext: {
                WidgetCenter.shared.reloadAllTimelines()
            })
    }
    
    func fetchAllCycles() -> Observable<[Cycle]> {
        return coreDataManager
            .fetch(
                entityType: PillCycleEntity.self,
                sortDescriptors: [
                    NSSortDescriptor(key: "createdAt", ascending: false),
                    NSSortDescriptor(key: "startDate", ascending: false)
                ]
            )
            .map { entities in
                return entities.map { $0.toDomain() }
            }
    }
    
    func fetchCycle(by id: UUID) -> Observable<Cycle?> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.coreDataManager.viewContext
            let fetchRequest: NSFetchRequest<PillCycleEntity> = NSFetchRequest(entityName: "PillCycleEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            do {
                let results = try context.fetch(fetchRequest)
                let cycle = results.first?.toDomain()
                observer.onNext(cycle)
                observer.onCompleted()
            } catch {
                observer.onError(CoreDataError.fetchFailed(error))
            }
            
            return Disposables.create()
        }
    }
}


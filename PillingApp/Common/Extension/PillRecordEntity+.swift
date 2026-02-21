import CoreData

// MARK: - Domain Model Conversion

extension PillRecordEntity {

    func toDomain() -> DayRecord {
        let pillStatus = CoreDataPillStatusMapper.fromLegacyInt(Int(status))
        let memoValue = memo ?? ""

        return DayRecord(
            id: id ?? UUID(),
            cycleDay: Int(cycleDay),
            status: pillStatus,
            scheduledDateTime: scheduledDateTime ?? Date(),
            takenAt: takenAt,
            memo: memoValue,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }

    static func from(
        domain: DayRecord,
        context: NSManagedObjectContext
    ) -> PillRecordEntity {
        let entity = PillRecordEntity(context: context)
        entity.id = domain.id
        entity.cycleDay = Int16(domain.cycleDay)
        entity.status = Int16(CoreDataPillStatusMapper.toLegacyInt(domain.status))
        entity.scheduledDateTime = domain.scheduledDateTime
        entity.takenAt = domain.takenAt
        entity.memo = domain.memo
        entity.createdAt = domain.createdAt
        entity.updatedAt = domain.updatedAt

        return entity
    }

    func update(from domain: DayRecord) {
        cycleDay = Int16(domain.cycleDay)
        status = Int16(CoreDataPillStatusMapper.toLegacyInt(domain.status))
        scheduledDateTime = domain.scheduledDateTime
        takenAt = domain.takenAt
        memo = domain.memo
        updatedAt = domain.updatedAt
    }
}


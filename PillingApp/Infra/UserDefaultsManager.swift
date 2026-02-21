import Foundation

protocol UserDefaultsManagerProtocol {
    func savePillInfo(_ pillInfo: PillInfo)
    func savePillStartDate(_ date: Date)
    func loadPillInfo() -> PillInfo?
    func loadPillStartDate() -> Date?
    func clearPillSettings()
    func saveCurrentCycleID(_ id: UUID)
    func loadCurrentCycleID() -> UUID?
    func hasCompletedOnboarding() -> Bool
    func setHasCompletedOnboarding(_ completed: Bool)

    func saveSideEffectTags(_ tags: [SideEffectTag])
    func loadSideEffectTags() -> [SideEffectTag]

    // 의약품 상세 정보 저장/로드
    func saveMedicationDetail(_ detail: MedicationDetailStoredInfo, forItemSeq itemSeq: String)
    func loadMedicationDetail(forItemSeq itemSeq: String) -> MedicationDetailStoredInfo?
}


final class UserDefaultsManager: UserDefaultsManagerProtocol {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        migrateIfNeeded()
    }
    
    // MARK: - Migration
    
    private func migrateIfNeeded() {
        // 이미 새 방식으로 저장되어 있으면 마이그레이션 불필요
        if userDefaults.data(forKey: UserDefaultsKey.pillInfo.rawValue) != nil {
            return
        }
        
        // 기존 방식으로 저장된 데이터가 있는지 확인
        guard let name = userDefaults.string(forKey: UserDefaultsKey.pillName.rawValue),
              userDefaults.object(forKey: UserDefaultsKey.pillTakingDays.rawValue) != nil,
              userDefaults.object(forKey: UserDefaultsKey.pillBreakDays.rawValue) != nil else {
            return
        }
        
        let takingDays = userDefaults.integer(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        let breakDays = userDefaults.integer(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        
        let pillInfo = PillInfo(name: name, takingDays: takingDays, breakDays: breakDays)
        
        // 새 방식으로 저장
        if let encoded = try? JSONEncoder().encode(pillInfo) {
            userDefaults.set(encoded, forKey: UserDefaultsKey.pillInfo.rawValue)
            
            // 기존 키들은 삭제 (선택사항 - 남겨둬도 무방)
            userDefaults.removeObject(forKey: UserDefaultsKey.pillName.rawValue)
            userDefaults.removeObject(forKey: UserDefaultsKey.pillTakingDays.rawValue)
            userDefaults.removeObject(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        }
    }
    
    // MARK: - Save Methods
    
    func savePillInfo(_ pillInfo: PillInfo) {
        if let encoded = try? JSONEncoder().encode(pillInfo) {
            userDefaults.set(encoded, forKey: UserDefaultsKey.pillInfo.rawValue)
        }
    }
    
    func savePillStartDate(_ date: Date) {
        userDefaults.set(date, forKey: UserDefaultsKey.pillStartDate.rawValue)
    }
    
    func saveCurrentCycleID(_ id: UUID) {
        userDefaults.set(id.uuidString, forKey: UserDefaultsKey.currentCycleID.rawValue)
    }
    
    
    // MARK: - Load Methods
    
    func loadPillInfo() -> PillInfo? {
        // 새 방식으로 먼저 시도
        if let data = userDefaults.data(forKey: UserDefaultsKey.pillInfo.rawValue) {
            print("🔍 [UserDefaults] PillInfo 데이터 존재, 디코딩 시도")
            if let pillInfo = try? JSONDecoder().decode(PillInfo.self, from: data) {
                print("🔍 [UserDefaults] PillInfo 로드 성공: \(pillInfo)")
                return pillInfo
            } else {
                print("❌ [UserDefaults] PillInfo JSON 디코딩 실패")
            }
        } else {
            print("🔍 [UserDefaults] PillInfo 데이터 없음, 기존 방식 시도")
        }

        // 혹시 마이그레이션이 안됐을 경우를 대비해 기존 방식으로도 시도
        let name = userDefaults.string(forKey: UserDefaultsKey.pillName.rawValue)
        let takingDaysObj = userDefaults.object(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        let breakDaysObj = userDefaults.object(forKey: UserDefaultsKey.pillBreakDays.rawValue)

        print("🔍 [UserDefaults] 기존 방식 - name: \(name ?? "nil"), takingDays: \(takingDaysObj != nil), breakDays: \(breakDaysObj != nil)")

        guard let name = name,
              takingDaysObj != nil,
              breakDaysObj != nil else {
            print("❌ PillInfo 로드 실패: 저장된 데이터가 없습니다")
            return nil
        }
        
        let takingDays = userDefaults.integer(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        let breakDays = userDefaults.integer(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        
        let pillInfo = PillInfo(name: name, takingDays: takingDays, breakDays: breakDays)
        
        // 기존 방식으로 불러온 경우, 새 방식으로 다시 저장
        savePillInfo(pillInfo)
        
        return pillInfo
    }
    
    func loadPillStartDate() -> Date? {
        return userDefaults.object(forKey: UserDefaultsKey.pillStartDate.rawValue) as? Date
    }
    
    func loadCurrentCycleID() -> UUID? {
        guard let uuidString = userDefaults.string(forKey: UserDefaultsKey.currentCycleID.rawValue) else {
            return nil
        }
        return UUID(uuidString: uuidString)
    }

    func hasCompletedOnboarding() -> Bool {
        return userDefaults.bool(forKey: UserDefaultsKey.hasCompletedOnboarding.rawValue)
    }

    func setHasCompletedOnboarding(_ completed: Bool) {
        userDefaults.set(completed, forKey: UserDefaultsKey.hasCompletedOnboarding.rawValue)
    }
    
    // MARK: - Clear Methods
    
    func clearPillSettings() {
        userDefaults.removeObject(forKey: UserDefaultsKey.pillInfo.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillName.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillTakingDays.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillBreakDays.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.pillStartDate.rawValue)
        userDefaults.removeObject(forKey: UserDefaultsKey.currentCycleID.rawValue) // ⭐️ 추가
    }
    
    /// 부작용 태그 저장
    func saveSideEffectTags(_ tags: [SideEffectTag]) {
        if let encoded = try? JSONEncoder().encode(tags) {
            userDefaults.set(encoded, forKey: UserDefaultsKey.sideEffectTags.rawValue)
        } else {
            print("   ❌ JSON 인코딩 실패")
        }
    }
    
    /// 부작용 태그 로드 (기본값 포함)
    func loadSideEffectTags() -> [SideEffectTag] {

        if let data = userDefaults.data(forKey: UserDefaultsKey.sideEffectTags.rawValue),
           let tags = try? JSONDecoder().decode([SideEffectTag].self, from: data) {
            return tags
        }

        print("⚠️ 저장된 태그 없음 - 기본 태그 생성 및 저장")
        let defaultTags = createDefaultSideEffectTags()
        saveSideEffectTags(defaultTags)  // 최초 생성 시 저장하여 UUID 고정
        return defaultTags
    }
    
    /// 기본 부작용 태그 생성
    private func createDefaultSideEffectTags() -> [SideEffectTag] {
        let defaultNames = [
            AppStrings.SideEffectTag.moodDown,
            AppStrings.SideEffectTag.spotting,
        ]

        return defaultNames.enumerated().map { index, name in
            SideEffectTag(
                name: name,
                isVisible: true,
                order: index,
                isDefault: true
            )
        }
    }

    // MARK: - Medication Detail Methods

    /// 의약품 상세 정보 저장
    func saveMedicationDetail(_ detail: MedicationDetailStoredInfo, forItemSeq itemSeq: String) {
        let key = UserDefaultsKey.medicationDetailKey(forItemSeq: itemSeq)
        if let encoded = try? JSONEncoder().encode(detail) {
            userDefaults.set(encoded, forKey: key)
        }
    }

    /// 의약품 상세 정보 로드
    func loadMedicationDetail(forItemSeq itemSeq: String) -> MedicationDetailStoredInfo? {
        let key = UserDefaultsKey.medicationDetailKey(forItemSeq: itemSeq)
        guard let data = userDefaults.data(forKey: key),
              let detail = try? JSONDecoder().decode(MedicationDetailStoredInfo.self, from: data) else {
            return nil
        }
        return detail
    }
}

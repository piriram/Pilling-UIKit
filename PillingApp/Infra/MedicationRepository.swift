import Foundation
import RxSwift

final class MedicationRepository: MedicationRepositoryProtocol {

    private let apiService: MedicationAPIServiceProtocol
    private let cacheKeyPrefix = "medication_cache_"
    private let timestampKeyPrefix = "medication_timestamp_"
    private let cacheTTL: TimeInterval = 7 * 24 * 60 * 60
    private let maxCacheEntries = 10
    private let isKoreanRegion: Bool

    init(apiService: MedicationAPIServiceProtocol) {
        self.apiService = apiService
        self.isKoreanRegion = Locale.current.region?.identifier == "KR"
    }

    func fetchContraceptivePills() -> Observable<[MedicationInfo]> {
        return searchMedication(keyword: "경구피임")
            .map { medications in
                medications.filter { $0.isContraceptivePill }
            }
    }

    func searchMedication(keyword: String) -> Observable<[MedicationInfo]> {
        let cacheKey = cacheKeyPrefix + keyword
        let timestampKey = timestampKeyPrefix + keyword

        if let cachedData = loadFromCache(key: cacheKey, timestampKey: timestampKey) {
            print("   💾 [Cache HIT] '\(keyword)' - 캐시에서 \(cachedData.count)개 로드")
            let filtered = filterContraceptivePills(cachedData, keyword: keyword)
            return Observable.just(filtered)
        }

        print("   📡 [Cache MISS] '\(keyword)' - 새로 검색 필요")

        guard isKoreanRegion else {
            print("   🌍 [Region] 한국 외 지역 - Fallback 데이터 사용")
            return getFallbackData(keyword: keyword)
        }

        print("   🌐 [API] '\(keyword)' - 공공데이터 API 호출 중...")
        return apiService.fetchMedications(keyword: keyword)
            .map { [weak self] medications -> [MedicationInfo] in
                guard let self = self else { return medications }
                return self.filterContraceptivePills(medications, keyword: keyword)
            }
            .do(onNext: { [weak self] medications in
                print("   💾 [Cache SAVE] '\(keyword)' - \(medications.count)개 약물 캐시에 저장")
                self?.saveToCache(medications, key: cacheKey, timestampKey: timestampKey)
            })
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.error(error)
                }
                print("   ⚠️ [API Error] '\(keyword)' - \(error.localizedDescription)")
                print("   🔄 [Fallback] '\(keyword)' - 로컬 데이터로 전환")
                return self.getFallbackData(keyword: keyword)
            }
    }

    private func filterContraceptivePills(_ medications: [MedicationInfo], keyword: String) -> [MedicationInfo] {
        let beforeCount = medications.count

        let filtered = medications.filter { medication in
            // 1. 피임제 타입 체크
            guard medication.productType.contains("[02540]") else {
                return false
            }

            // 2. 키워드 매칭 정확도 체크 (부분 일치가 아닌 시작 일치)
            let normalizedName = medication.name.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "정", with: "")

            let normalizedKeyword = keyword.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "정", with: "")

            // 약 이름이 키워드로 시작하는지 체크
            return normalizedName.hasPrefix(normalizedKeyword)
        }

        let filteredCount = beforeCount - filtered.count
        if filteredCount > 0 {
            print("   🔍 [Filter] '\(keyword)' - 피임제 외 \(filteredCount)개 제외")
        }

        return filtered
    }

    func refreshCache() -> Observable<Void> {
        return Observable.create { observer in
            self.clearAllCache()
            observer.onNext(())
            observer.onCompleted()
            return Disposables.create()
        }
    }

    private func loadFromCache(key: String, timestampKey: String) -> [MedicationInfo]? {
        guard let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date,
              Date().timeIntervalSince(timestamp) < cacheTTL,
              let data = UserDefaults.standard.data(forKey: key),
              let medications = try? JSONDecoder().decode([MedicationInfo].self, from: data) else {
            return nil
        }
        return medications
    }

    private func saveToCache(_ medications: [MedicationInfo], key: String, timestampKey: String) {
        guard let data = try? JSONEncoder().encode(medications) else {
            print("   ❌ [Cache] 인코딩 실패")
            return
        }
        UserDefaults.standard.set(data, forKey: key)
        UserDefaults.standard.set(Date(), forKey: timestampKey)

        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let cacheCount = allKeys.filter { $0.hasPrefix(timestampKeyPrefix) }.count
        print("   📦 [Cache] 현재 캐시 항목 수: \(cacheCount)/\(maxCacheEntries)")

        cleanupOldCacheEntries()
    }

    private func cleanupOldCacheEntries() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let timestampKeys = allKeys.filter { $0.hasPrefix(timestampKeyPrefix) }

        var cacheEntries: [(key: String, timestamp: Date)] = []
        for timestampKey in timestampKeys {
            if let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date {
                cacheEntries.append((key: timestampKey, timestamp: timestamp))
            }
        }

        cacheEntries.sort { $0.timestamp > $1.timestamp }

        if cacheEntries.count > maxCacheEntries {
            let entriesToRemove = cacheEntries.dropFirst(maxCacheEntries)
            print("   🧹 [Cache Cleanup] \(entriesToRemove.count)개 오래된 캐시 삭제")
            for entry in entriesToRemove {
                let keyword = entry.key.replacingOccurrences(of: timestampKeyPrefix, with: "")
                print("      ↳ 삭제: '\(keyword)'")
                let cacheKey = entry.key.replacingOccurrences(of: timestampKeyPrefix, with: cacheKeyPrefix)
                UserDefaults.standard.removeObject(forKey: entry.key)
                UserDefaults.standard.removeObject(forKey: cacheKey)
            }
        }
    }

    private func clearAllCache() {
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let cacheKeys = allKeys.filter { $0.hasPrefix(cacheKeyPrefix) || $0.hasPrefix(timestampKeyPrefix) }
        for key in cacheKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func getFallbackData(keyword: String) -> Observable<[MedicationInfo]> {
        let normalizedKeyword = keyword.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "정", with: "")

        let fallbackPills = Self.getHardcodedPills()

        let matchedPills = fallbackPills.filter { pill in
            let pillName = pill.name.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "정", with: "")
            return pillName.contains(normalizedKeyword)
        }

        print("   📚 [Fallback] '\(keyword)' - 로컬에서 \(matchedPills.count)개 매칭")
        if matchedPills.isEmpty {
            print("      ⚠️ 매칭된 약물 없음")
        } else {
            print("      ↳ \(matchedPills.map { $0.name }.joined(separator: ", "))")
        }

        return Observable.just(matchedPills)
    }

    private static func getHardcodedPills() -> [MedicationInfo] {
        return [
            MedicationInfo(
                id: "머시론",
                name: "머시론",
                manufacturer: "바이엘코리아",
                mainIngredient: "에티닐에스트라디올, 데소게스트렐",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "",
                imageURL: "",
                productType: "피임제"
            ),
            MedicationInfo(
                id: "야즈",
                name: "야즈",
                manufacturer: "바이엘코리아",
                mainIngredient: "에티닐에스트라디올, 드로스피레논",
                materialName: "",
                dosageInstructions: "24일 복용 + 4일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "",
                imageURL: "",
                productType: "피임제"
            ),
            MedicationInfo(
                id: "야스민",
                name: "야스민",
                manufacturer: "바이엘코리아",
                mainIngredient: "에티닐에스트라디올, 드로스피레논",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "",
                imageURL: "",
                productType: "피임제"
            ),
            MedicationInfo(
                id: "센스데이",
                name: "센스데이",
                manufacturer: "한국오가논",
                mainIngredient: "에티닐에스트라디올, 레보노르게스트렐",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "",
                imageURL: "",
                productType: "피임제"
            ),
            MedicationInfo(
                id: "마이보라",
                name: "마이보라",
                manufacturer: "바이엘코리아",
                mainIngredient: "에티닐에스트라디올, 레보노르게스트렐",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "",
                imageURL: "",
                productType: "피임제"
            ),
            MedicationInfo(
                id: "멜리안",
                name: "멜리안",
                manufacturer: "한국오가논",
                mainIngredient: "에티닐에스트라디올, 데소게스트렐",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "",
                imageURL: "",
                productType: "피임제"
            )
        ]
    }
}

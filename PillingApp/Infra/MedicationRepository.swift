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

        // 한국 외 지역은 캐시 우선 사용
        guard isKoreanRegion else {
            if let cachedData = loadFromCache(key: cacheKey, timestampKey: timestampKey) {
                let filtered = filterContraceptivePills(cachedData, keyword: keyword)
                return Observable.just(filtered)
            }
            return getFallbackData(keyword: keyword)
        }

        // 한국 지역: API 우선 호출
        return apiService.fetchMedications(keyword: keyword)
            .map { [weak self] medications -> [MedicationInfo] in
                guard let self = self else { return medications }
                return self.filterContraceptivePills(medications, keyword: keyword)
            }
            .flatMap { [weak self] filteredResults -> Observable<[MedicationInfo]> in
                guard let self = self else { return Observable.just(filteredResults) }

                // API 결과가 있으면 캐시 저장하고 반환
                if !filteredResults.isEmpty {
                    self.saveToCache(filteredResults, key: cacheKey, timestampKey: timestampKey)
                    return Observable.just(filteredResults)
                }

                // API 결과가 없으면 캐시 확인
                if let cachedData = self.loadFromCache(key: cacheKey, timestampKey: timestampKey) {
                    let cached = self.filterContraceptivePills(cachedData, keyword: keyword)
                    return Observable.just(cached)
                }

                // 캐시도 없으면 빈 배열 반환
                return Observable.just([])
            }
            .catch { [weak self] error in
                guard let self = self else {
                    return Observable.just([])
                }

                // API 에러 시 캐시 확인
                if let cachedData = self.loadFromCache(key: cacheKey, timestampKey: timestampKey) {
                    let cached = self.filterContraceptivePills(cachedData, keyword: keyword)
                    return Observable.just(cached)
                }

                // 캐시도 없으면 빈 배열 반환
                return Observable.just([])
            }
    }

    private func filterContraceptivePills(_ medications: [MedicationInfo], keyword: String) -> [MedicationInfo] {
        // isContraceptivePill 사용 ([02540] 피임제 + [02470] 난포호르몬제 및 황체호르몬제)
        return medications.filter { $0.isContraceptivePill }
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
            return
        }
        UserDefaults.standard.set(data, forKey: key)
        UserDefaults.standard.set(Date(), forKey: timestampKey)
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
            for entry in entriesToRemove {
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

        let fallbackPills = Self.getHardcodedPillsData()

        let matchedPills = fallbackPills.filter { pill in
            let pillName = pill.name.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "정", with: "")
            return pillName.contains(normalizedKeyword)
        }

        return Observable.just(matchedPills)
    }

    func getHardcodedPills() -> [MedicationInfo] {
        return Self.getHardcodedPillsData()
    }

    private static func getHardcodedPillsData() -> [MedicationInfo] {
        // 순서: initialSearchKeywords와 동일하게 유지 ["머시론","센스데이","멜리안","마이보라","야즈","야스민"]
        return [
            MedicationInfo(
                id: "200009522",
                name: "머시론정",
                manufacturer: "알보젠코리아(주)",
                mainIngredient: "Desogestrel/Ethinyl Estradiol",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "20000616",
                imageURL: "https://nedrug.mfds.go.kr/pbp/cmn/itemImageDownload/1MpYN6WeYa0",
                productType: "[02540]피임제",
                takingDays: 21,
                breakDays: 7,
                detailInfo: nil
            ),
            MedicationInfo(
                id: "201706350",
                name: "센스데이정",
                manufacturer: "(주)유한양행",
                mainIngredient: "Desogestrel/Ethinyl Estradiol",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "20170731",
                imageURL: "https://nedrug.mfds.go.kr/pbp/cmn/itemImageDownload/154609816285900048",
                productType: "[02540]피임제",
                takingDays: 21,
                breakDays: 7,
                detailInfo: nil
            ),
            MedicationInfo(
                id: "200807207",
                name: "멜리안정",
                manufacturer: "동아제약(주)",
                mainIngredient: "Ethinyl Estradiol/Gestodene",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "20080627",
                imageURL: "https://nedrug.mfds.go.kr/pbp/cmn/itemImageDownload/147427893111400138",
                productType: "[02540]피임제",
                takingDays: 21,
                breakDays: 7,
                detailInfo: nil
            ),
            MedicationInfo(
                id: "200800687",
                name: "마이보라정",
                manufacturer: "동아제약(주)",
                mainIngredient: "Ethinyl Estradiol/Gestodene",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "20080117",
                imageURL: "https://nedrug.mfds.go.kr/pbp/cmn/itemImageDownload/147427878780200121",
                productType: "[02540]피임제",
                takingDays: 21,
                breakDays: 7,
                detailInfo: nil
            ),
            MedicationInfo(
                id: "200807400",
                name: "야즈정",
                manufacturer: "바이엘코리아(주)",
                mainIngredient: "Drospirenone/Ethinyl Estradiol Inclusion Complex",
                materialName: "",
                dosageInstructions: "24일 복용 + 4일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "20080703",
                imageURL: "https://nedrug.mfds.go.kr/pbp/cmn/itemImageDownload/147427897731800020",
                productType: "[02540]피임제",
                takingDays: 24,
                breakDays: 4,
                detailInfo: nil
            ),
            MedicationInfo(
                id: "200801550",
                name: "야스민정",
                manufacturer: "바이엘코리아(주)",
                mainIngredient: "Drospirenone/Ethinyl Estradiol",
                materialName: "",
                dosageInstructions: "21일 복용 + 7일 휴약",
                packUnit: "",
                storageMethod: "",
                permitDate: "20080204",
                imageURL: "https://nedrug.mfds.go.kr/pbp/cmn/itemImageDownload/147427847082700145",
                productType: "[02540]피임제",
                takingDays: 21,
                breakDays: 7,
                detailInfo: nil
            )
        ]
    }
}

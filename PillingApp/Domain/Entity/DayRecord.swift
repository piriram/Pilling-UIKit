import Foundation
// MARK: - PillInfo

struct PillInfo: Codable{
    let name: String
    let takingDays: Int
    let breakDays: Int
    let manufacturer: String?
    let mainIngredient: String?
    let dosageInstructions: String?
    let itemSeq: String?

    init(name: String, takingDays: Int, breakDays: Int, manufacturer: String? = nil, mainIngredient: String? = nil, dosageInstructions: String? = nil, itemSeq: String? = nil) {
        self.name = name
        self.takingDays = takingDays
        self.breakDays = breakDays
        self.manufacturer = manufacturer
        self.mainIngredient = mainIngredient
        self.dosageInstructions = dosageInstructions
        self.itemSeq = itemSeq
    }
}

// MARK: - PillRecordMemo

struct PillRecordMemo: Codable {
    let text: String
    let sideEffectIds: [String]
    let sideEffectNames: [String: String]?  // Optional: tagId -> tagName mapping (삭제된 태그 이름 보존용)

    init(text: String, sideEffectIds: [String] = [], sideEffectNames: [String: String]? = nil) {
        self.text = text
        self.sideEffectIds = sideEffectIds
        self.sideEffectNames = sideEffectNames
    }

    /// JSON 문자열로 인코딩
    func toJSONString() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{\"text\":\"\",\"sideEffectIds\":[]}"
        }
        return jsonString
    }

    /// JSON 문자열에서 디코딩
    static func fromJSONString(_ jsonString: String) -> PillRecordMemo {
        guard let data = jsonString.data(using: .utf8),
              let memo = try? JSONDecoder().decode(PillRecordMemo.self, from: data) else {
            // 기존 plain text 메모 호환성 처리
            return PillRecordMemo(text: jsonString, sideEffectIds: [], sideEffectNames: nil)
        }
        return memo
    }
}

// MARK: - Domain/Entities/PillRecord.swift

struct DayRecord {
    let id: UUID
    let cycleDay: Int
    let status: PillStatus
    let scheduledDateTime: Date
    let takenAt: Date?
    let memo: String
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - DayRecord + SideEffect

extension DayRecord {

    /// 메모에서 PillRecordMemo 파싱
    var parsedMemo: PillRecordMemo {
        return PillRecordMemo.fromJSONString(memo)
    }

    /// 메모 텍스트만 추출
    var memoText: String {
        return parsedMemo.text
    }

    /// 부작용 태그 ID 목록 추출
    var sideEffectIds: [String] {
        return parsedMemo.sideEffectIds
    }

    /// 특정 부작용 태그가 포함되어 있는지 확인
    func hasSideEffect(tagId: String) -> Bool {
        return sideEffectIds.contains(tagId)
    }
}

// MARK: - DayRecord Array + Statistics

extension Array where Element == DayRecord {

    /// 부작용별 발생 횟수 통계
    func sideEffectStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]

        for record in self {
            for tagId in record.sideEffectIds {
                stats[tagId, default: 0] += 1
            }
        }

        return stats
    }

    /// 특정 부작용 태그를 가진 레코드 필터링
    func filterBySideEffect(tagId: String) -> [DayRecord] {
        return filter { $0.hasSideEffect(tagId: tagId) }
    }

    /// 날짜 범위 내에서 부작용 통계 (옵션)
    func sideEffectStatistics(from startDate: Date, to endDate: Date) -> [String: Int] {
        return filter { record in
            record.scheduledDateTime >= startDate && record.scheduledDateTime <= endDate
        }.sideEffectStatistics()
    }
}

//

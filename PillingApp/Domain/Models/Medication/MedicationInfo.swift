import Foundation

// MARK: - MedicationDetailStoredInfo

struct MedicationDetailStoredInfo: Codable {
    let efficacy: String          // 효능효과
    let useMethod: String         // 사용법
    let precautions: String       // 주의사항
    let sideEffects: String       // 부작용
    let storage: String           // 보관법
}

// MARK: - MedicationInfo

struct MedicationInfo: Codable {
    let id: String
    let name: String
    let manufacturer: String
    let mainIngredient: String
    let materialName: String
    let dosageInstructions: String
    let packUnit: String
    let storageMethod: String
    let permitDate: String
    let imageURL: String
    let productType: String

    // 복용 주기 (Int로 관리)
    let takingDays: Int?
    let breakDays: Int?

    // 상세 정보 (AI 챗봇용, Optional)
    let detailInfo: MedicationDetailStoredInfo?
}

extension MedicationInfo {
    var isContraceptivePill: Bool {
        // productType 코드로 직접 체크 (더 정확)
        let contraceptiveCodes = ["[02540]", "[02470]"]  // 피임제, 난포호르몬제 및 황체호르몬제
        if contraceptiveCodes.contains(where: { productType.contains($0) }) {
            return true
        }

        // 이름에 키워드 포함 여부 체크 (백업)
        let keywords = ["경구피임", "피임약", "피임제"]
        return keywords.contains { name.contains($0) }
    }

    func matchesSearchQuery(_ query: String) -> Bool {
        let normalizedQuery = query.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "정", with: "")

        let normalizedName = name.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "정", with: "")

        return normalizedName.contains(normalizedQuery)
    }

    func toPillInfo() -> PillInfo {
        let dosage = DosageParser.parse(dosageText: dosageInstructions)
        return PillInfo(
            name: name,
            takingDays: dosage.takingDays,
            breakDays: dosage.breakDays,
            manufacturer: manufacturer,
            mainIngredient: mainIngredient,
            dosageInstructions: dosageInstructions,
            itemSeq: id
        )
    }

    var dosagePatternText: String {
        let dosage = DosageParser.parse(dosageText: dosageInstructions)
        return "\(dosage.takingDays)일 복용 · \(dosage.breakDays)일 휴약"
    }

    var productTypeDisplay: String {
        let trimmed = productType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let endIndex = trimmed.firstIndex(of: "]") {
            let startIndex = trimmed.index(after: endIndex)
            return String(trimmed[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return trimmed
    }
}

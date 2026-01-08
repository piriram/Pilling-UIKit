import Foundation

// MARK: - 의약품개요정보(e약은요) API Response

struct MedicationDetailAPIResponse: Codable {
    let header: ResponseHeader
    let body: MedicationDetailBody
}

struct MedicationDetailBody: Codable {
    let items: [MedicationDetailItem]
    let numOfRows: Int
    let pageNo: Int
    let totalCount: Int
}

struct MedicationDetailItem: Codable {
    let itemSeq: String?          // 품목기준코드
    let itemName: String?         // 제품명
    let entpName: String?         // 업체명
    let efcyQesitm: String?       // 효능효과 ("이 약은 무엇에 사용합니까?")
    let useMethodQesitm: String?  // 사용법 ("이 약은 어떻게 사용합니까?")
    let atpnWarnQesitm: String?   // 주의사항 경고
    let atpnQesitm: String?       // 주의사항
    let intrcQesitm: String?      // 상호작용
    let seQesitm: String?         // 부작용
    let depositMethodQesitm: String? // 보관법
    let openDe: String?           // 공개일자
    let updateDe: String?         // 수정일자
    let itemImage: String?        // 낱알이미지

    enum CodingKeys: String, CodingKey {
        case itemSeq
        case itemName
        case entpName
        case efcyQesitm
        case useMethodQesitm
        case atpnWarnQesitm
        case atpnQesitm
        case intrcQesitm
        case seQesitm
        case depositMethodQesitm
        case openDe
        case updateDe
        case itemImage
    }
}

// MARK: - Domain Model Extension

extension MedicationDetailItem {
    func toDomainModel() -> MedicationDetailInfo {
        return MedicationDetailInfo(
            itemSeq: itemSeq ?? "",
            itemName: itemName ?? "",
            entpName: entpName ?? "",
            efficacy: cleanHTML(efcyQesitm),
            useMethod: cleanHTML(useMethodQesitm),
            precautions: cleanHTML(atpnQesitm),
            sideEffects: cleanHTML(seQesitm),
            storage: cleanHTML(depositMethodQesitm),
            dosageInstructions: parseDosageInstructions(useMethodQesitm)
        )
    }

    // HTML 태그 제거
    private func cleanHTML(_ html: String?) -> String {
        guard let html = html else { return "" }

        return html
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 복용 주기 파싱
    private func parseDosageInstructions(_ useMethod: String?) -> String {
        let text = cleanHTML(useMethod).lowercased()

        guard !text.isEmpty else {
            return "21일 복용 + 7일 휴약"
        }

        // "26일간", "26정", "26일 복용" 등 패턴 감지
        if text.contains("26일") || text.contains("26정") || text.contains("26회") {
            return "26일 복용 + 2일 휴약"
        }

        // "24일간", "24정", "24일 복용" 등 패턴 감지
        if text.contains("24일") || text.contains("24정") || text.contains("24회") {
            return "24일 복용 + 4일 휴약"
        }

        // "21일간", "21정", "21일 복용" 등 패턴 감지
        if text.contains("21일") || text.contains("21정") || text.contains("21회") {
            return "21일 복용 + 7일 휴약"
        }

        // 기본값
        return "21일 복용 + 7일 휴약"
    }
}

// MARK: - Domain Model

struct MedicationDetailInfo {
    let itemSeq: String
    let itemName: String
    let entpName: String
    let efficacy: String          // 효능효과
    let useMethod: String         // 사용법
    let precautions: String       // 주의사항
    let sideEffects: String       // 부작용
    let storage: String           // 보관법
    let dosageInstructions: String // 복용 주기 (파싱된 결과)

    // MedicationDetailStoredInfo로 변환
    func toStoredInfo() -> MedicationDetailStoredInfo {
        return MedicationDetailStoredInfo(
            efficacy: efficacy,
            useMethod: useMethod,
            precautions: precautions,
            sideEffects: sideEffects,
            storage: storage
        )
    }

    // 복용일/휴약일을 Int로 파싱
    func parsedDosage() -> (takingDays: Int, breakDays: Int) {
        let text = dosageInstructions.lowercased()

        if text.contains("26일") || text.contains("26정") {
            return (26, 2)
        } else if text.contains("24일") || text.contains("24정") {
            return (24, 4)
        } else if text.contains("21일") || text.contains("21정") {
            return (21, 7)
        }

        // 기본값
        return (21, 7)
    }
}

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
        case itemSeq = "ITEM_SEQ"
        case itemName = "ITEM_NAME"
        case entpName = "ENTP_NAME"
        case efcyQesitm = "EFCY_QESITM"
        case useMethodQesitm = "USE_METHOD_QESITM"
        case atpnWarnQesitm = "ATPN_WARN_QESITM"
        case atpnQesitm = "ATPN_QESITM"
        case intrcQesitm = "INTRC_QESITM"
        case seQesitm = "SE_QESITM"
        case depositMethodQesitm = "DEPOSIT_METHOD_QESITM"
        case openDe = "OPEN_DE"
        case updateDe = "UPDATE_DE"
        case itemImage = "ITEM_IMAGE"
    }
}

// MARK: - Domain Model Extension

extension MedicationDetailItem {
    func toDomainModel() -> MedicationDetailInfo {
        MedicationDetailInfo(
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
        print("🔍 [복용주기 파싱] ==================")
        print("📄 원본: \(useMethod?.prefix(200) ?? "nil")")

        let cleanedText = cleanHTML(useMethod)
        print("🧹 HTML 제거: \(cleanedText.prefix(200))")

        let text = cleanedText.lowercased()
        print("🔤 소문자 변환: \(text.prefix(200))")

        guard !text.isEmpty else {
            print("⚠️ 빈 텍스트 → 기본값 21/7")
            return "21일 복용 + 7일 휴약"
        }

        // "24일간", "24정", "24일 복용" 등 패턴 감지
        let has24Days = text.contains("24일")
        let has24Pills = text.contains("24정")
        let has24Times = text.contains("24회")
        print("🔍 24 패턴: 24일=\(has24Days), 24정=\(has24Pills), 24회=\(has24Times)")

        if has24Days || has24Pills || has24Times {
            print("✅ 결과: 24일 복용 + 4일 휴약")
            return "24일 복용 + 4일 휴약"
        }

        // "21일간", "21정", "21일 복용" 등 패턴 감지
        let has21Days = text.contains("21일")
        let has21Pills = text.contains("21정")
        let has21Times = text.contains("21회")
        print("🔍 21 패턴: 21일=\(has21Days), 21정=\(has21Pills), 21회=\(has21Times)")

        if has21Days || has21Pills || has21Times {
            print("✅ 결과: 21일 복용 + 7일 휴약")
            return "21일 복용 + 7일 휴약"
        }

        // 기본값
        print("⚠️ 패턴 미감지 → 기본값 21/7")
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
        print("🔢 [Int 파싱] dosageInstructions: \(dosageInstructions)")
        let text = dosageInstructions.lowercased()

        let has24Days = text.contains("24일")
        let has24Pills = text.contains("24정")
        print("🔍 24 패턴: 24일=\(has24Days), 24정=\(has24Pills)")

        if has24Days || has24Pills {
            print("✅ Int 결과: (24, 4)")
            return (24, 4)
        }

        let has21Days = text.contains("21일")
        let has21Pills = text.contains("21정")
        print("🔍 21 패턴: 21일=\(has21Days), 21정=\(has21Pills)")

        if has21Days || has21Pills {
            print("✅ Int 결과: (21, 7)")
            return (21, 7)
        }

        // 기본값
        print("⚠️ 패턴 미감지 → Int 기본값 (21, 7)")
        return (21, 7)
    }
}

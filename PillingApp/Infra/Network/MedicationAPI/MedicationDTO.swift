import Foundation

struct MedicationAPIResponse: Codable {
    let header: ResponseHeader
    let body: ResponseBody
}

struct ResponseHeader: Codable {
    let resultCode: String
    let resultMsg: String
}

struct ResponseBody: Codable {
    let items: [MedicationItem]
    let numOfRows: Int
    let pageNo: Int
    let totalCount: Int
}

struct MedicationItem: Codable {
    let itemSeq: String?
    let itemName: String?
    let entpName: String?
    let itemIngrName: String?
    let materialName: String?
    let packUnit: String?
    let storageMethod: String?
    let itemPermitDate: String?
    let bigPrdtImgUrl: String?
    let productType: String?
    let cancelDate: String?
    let cancelName: String?

    enum CodingKeys: String, CodingKey {
        case itemSeq = "ITEM_SEQ"
        case itemName = "ITEM_NAME"
        case entpName = "ENTP_NAME"
        case itemIngrName = "ITEM_INGR_NAME"
        case materialName = "MATERIAL_NAME"
        case packUnit = "PACK_UNIT"
        case storageMethod = "STORAGE_METHOD"
        case itemPermitDate = "ITEM_PERMIT_DATE"
        case bigPrdtImgUrl = "BIG_PRDT_IMG_URL"
        case productType = "PRDUCT_TYPE"
        case cancelDate = "CANCEL_DATE"
        case cancelName = "CANCEL_NAME"
    }

    var isValid: Bool {
        // CANCEL_DATE가 존재하면 취소/만료된 약품이므로 제외
        guard cancelDate == nil || cancelDate?.isEmpty == true else {
            return false
        }
        return true
    }

    // 성분 정보를 기반으로 복용 주기 추론
    private func inferDosageInstructions() -> String {
        guard let ingredient = itemIngrName?.lowercased() else {
            return "21일 복용 + 7일 휴약"
        }

        // Drospirenone 성분이 포함된 약품은 24-4 주기 (야즈 계열)
        if ingredient.contains("drospirenone") {
            return "24일 복용 + 4일 휴약"
        }

        // 나머지는 일반적인 21-7 주기
        return "21일 복용 + 7일 휴약"
    }
}

extension MedicationItem {
    func toDomainModel() -> MedicationInfo {
        let dosageText = inferDosageInstructions()
        let dosage = DosageParser.parse(dosageText: dosageText)

        return MedicationInfo(
            id: itemSeq ?? "",
            name: itemName ?? "",
            manufacturer: entpName ?? "",
            mainIngredient: itemIngrName ?? "",
            materialName: materialName ?? "",
            dosageInstructions: dosageText,
            packUnit: packUnit ?? "",
            storageMethod: storageMethod ?? "",
            permitDate: itemPermitDate ?? "",
            imageURL: bigPrdtImgUrl ?? "",
            productType: productType ?? "",
            takingDays: dosage.takingDays,
            breakDays: dosage.breakDays,
            detailInfo: nil
        )
    }
}

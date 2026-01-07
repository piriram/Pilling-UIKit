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
    let mainItemIngr: String?
    let materialName: String?
    let udDocData: String?
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
        case mainItemIngr = "MAIN_ITEM_INGR"
        case materialName = "MATERIAL_NAME"
        case udDocData = "UD_DOC_DATA"
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
}

extension MedicationItem {
    func toDomainModel() -> MedicationInfo {
        MedicationInfo(
            id: itemSeq ?? "",
            name: itemName ?? "",
            manufacturer: entpName ?? "",
            mainIngredient: mainItemIngr ?? "",
            materialName: materialName ?? "",
            dosageInstructions: udDocData ?? "",
            packUnit: packUnit ?? "",
            storageMethod: storageMethod ?? "",
            permitDate: itemPermitDate ?? "",
            imageURL: bigPrdtImgUrl ?? "",
            productType: productType ?? ""
        )
    }
}

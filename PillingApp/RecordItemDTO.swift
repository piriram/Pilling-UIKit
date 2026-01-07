import Foundation

// MARK: - DTO
struct RecordItemDTO {
    let category: String
    let percentage: Int
    let days: Int
    let colorHex: String
    let isChartOnly: Bool  // 차트에만 표시, 리스트에는 표시 안함
}

struct SideEffectStatDTO {
    let tagId: String
    let tagName: String
    let count: Int
}

struct PeriodRecordDTO {
    let startDate: String
    let endDate: String
    let startDateShort: String
    let endDateShort: String
    let completionRate: Int
    let medicineName: String
    let records: [RecordItemDTO]
    let skippedCount: Int
    let sideEffectStats: [SideEffectStatDTO]
    let isEmpty: Bool
}

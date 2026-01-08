import Foundation

enum UserDefaultsKey: String {
    case pillName = "pill_name"
    case pillTakingDays = "pill_taking_days"
    case pillBreakDays = "pill_break_days"
    case pillStartDate = "pill_start_date"
    case pillInfo = "pillInfo"
    case currentCycleID = "current_cycle_id"
    case sideEffectTags = "side_effect_tags"
    case hasCompletedOnboarding = "has_completed_onboarding"
    case medicationDetailPrefix = "medication_detail_"  // 품목기준코드별 상세 정보 저장

    // 품목기준코드로 상세 정보 키 생성
    static func medicationDetailKey(forItemSeq itemSeq: String) -> String {
        return UserDefaultsKey.medicationDetailPrefix.rawValue + itemSeq
    }
}

enum AppError: Error {
    case coreDataFetchFailed(reason: String)
    case coreDataSaveFailed(reason: String)
    case invalidCycleData(reason: String)
    case notificationPermissionDenied
    case userDefaultsCorrupted
    case unexpectedNilValue(context: String)

    var crashlyticsInfo: [String: Any] {
        switch self {
        case .coreDataFetchFailed(let reason):
            return ["error_type": "coredata_fetch", "reason": reason]
        case .coreDataSaveFailed(let reason):
            return ["error_type": "coredata_save", "reason": reason]
        case .invalidCycleData(let reason):
            return ["error_type": "invalid_cycle", "reason": reason]
        case .notificationPermissionDenied:
            return ["error_type": "notification_permission"]
        case .userDefaultsCorrupted:
            return ["error_type": "userdefaults_corrupted"]
        case .unexpectedNilValue(let context):
            return ["error_type": "unexpected_nil", "context": context]
        }
    }
}

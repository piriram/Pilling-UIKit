import FirebaseCrashlytics

final class FirebaseCrashlyticsService: CrashlyticsServiceProtocol {
    private let crashlytics = Crashlytics.crashlytics()

    func logError(_ error: Error, userInfo: [String: Any]? = nil) {
        if let info = userInfo {
            info.forEach { crashlytics.setCustomValue($0.value, forKey: $0.key) }
        }
        crashlytics.record(error: error)
    }

    func recordNonFatalError(_ error: Error) {
        crashlytics.record(error: error)
    }

    func setUserID(_ userID: String) {
        crashlytics.setUserID(userID)
    }

    func setCustomValue(_ value: Any, forKey key: String) {
        crashlytics.setCustomValue(value, forKey: key)
    }

    func log(_ message: String) {
        crashlytics.log(message)
    }

    func logCritical(_ message: String, error: Error? = nil) {
        crashlytics.log("🔴 CRITICAL: \(message)")
        if let error = error {
            crashlytics.record(error: error)
        }
    }
}

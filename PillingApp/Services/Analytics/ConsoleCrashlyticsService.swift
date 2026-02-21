final class ConsoleCrashlyticsService: CrashlyticsServiceProtocol {
    func logError(_ error: Error, userInfo: [String: Any]? = nil) {
        print("🔥 [Crashlytics] Error: \(error)")
        if let info = userInfo {
            print("   UserInfo: \(info)")
        }
    }

    func recordNonFatalError(_ error: Error) {
        print("⚠️ [Crashlytics] Non-fatal: \(error)")
    }

    func setUserID(_ userID: String) {
        print("👤 [Crashlytics] UserID: \(userID)")
    }

    func setCustomValue(_ value: Any, forKey key: String) {
        print("🔧 [Crashlytics] Custom[\(key)]: \(value)")
    }

    func log(_ message: String) {
        print("📝 [Crashlytics] Log: \(message)")
    }

    func logCritical(_ message: String, error: Error? = nil) {
        print("🔴 [Crashlytics] CRITICAL: \(message)")
        if let error = error {
            print("   Error: \(error)")
        }
    }
}

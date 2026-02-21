protocol CrashlyticsServiceProtocol {
    func logError(_ error: Error, userInfo: [String: Any]?)
    func recordNonFatalError(_ error: Error)
    func setUserID(_ userID: String)
    func setCustomValue(_ value: Any, forKey key: String)
    func log(_ message: String)
    func logCritical(_ message: String, error: Error?)
}

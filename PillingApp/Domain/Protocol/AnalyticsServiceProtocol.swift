import Foundation

protocol AnalyticsServiceProtocol {
    func logEvent(_ event: AnalyticsEvent)
    func setUserProperty(key: String, value: String)
}

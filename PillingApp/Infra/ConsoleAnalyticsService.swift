import Foundation

final class ConsoleAnalyticsService: AnalyticsServiceProtocol {
    func logEvent(_ event: AnalyticsEvent) {
        print("📊 [Analytics] \(event.name)")
        print("   Parameters: \(event.parameters)")
    }

    func setUserProperty(key: String, value: String) {
        print("👤 [Analytics] UserProperty: \(key) = \(value)")
    }
}

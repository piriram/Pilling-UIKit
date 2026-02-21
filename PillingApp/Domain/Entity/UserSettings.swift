import UIKit
import RxSwift
// MARK: - Domain/RepositoryProtocols/UserSettingsRepositoryProtocol.swift

protocol UserDefaultsProtocol {
    func fetchSettings() -> Observable<UserSettings>
    func saveSettings(_ settings: UserSettings) -> Observable<Void>
}
// MARK: - Domain/Entities/UserSettings.swift

struct UserSettings {
    static let defaultNotificationMessage: String = AppStrings.Notification.defaultMessage
    
    let scheduledTime: Date
    let notificationEnabled: Bool
    let delayThresholdMinutes: Int
    let notificationMessage: String
    
    init(
        scheduledTime: Date,
        notificationEnabled: Bool,
        delayThresholdMinutes: Int,
        notificationMessage: String = UserSettings.defaultNotificationMessage
    ) {
        self.scheduledTime = scheduledTime
        self.notificationEnabled = notificationEnabled
        self.delayThresholdMinutes = delayThresholdMinutes
        self.notificationMessage = notificationMessage
    }
    
    static var `default`: UserSettings {
        let calendar = Calendar.current
        // 고정된 기본 시간 사용 (9:00 AM)
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        let scheduledTime = calendar.date(from: components) ?? Date()

        return UserSettings(
            scheduledTime: scheduledTime,
            notificationEnabled: true,
            delayThresholdMinutes: 120,
            notificationMessage: UserSettings.defaultNotificationMessage
        )
    }
}


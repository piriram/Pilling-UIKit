import Foundation
import UserNotifications
import RxSwift

final class LocalNotificationManager: NotificationManagerProtocol {
    
    // MARK: - Properties
    
    private let notificationCenter: UNUserNotificationCenter
    private let notificationIdentifier = "dailyPillReminder"
    
    // MARK: - Initialization
    
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }
    
    // MARK: - NotificationManagerProtocol
    
    func requestAuthorization() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NotificationError.schedulingFailed)
                return Disposables.create()
            }
            
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            self.notificationCenter.requestAuthorization(options: options) { granted, error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                observer.onNext(granted)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func scheduleDailyNotification(at time: Date, isEnabled: Bool, message: String, cycle: Cycle? = nil) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NotificationError.schedulingFailed)
                return Disposables.create()
            }

            // 기존 알림 삭제
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [self.notificationIdentifier])

            // 알림이 비활성화된 경우 바로 완료
            guard isEnabled else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }

            // 위약 기간인지 확인하여 메시지 결정
            let finalMessage: String
            if let cycle = cycle, cycle.isCurrentlyInBreakPeriod() {
                finalMessage = AppStrings.Notification.breakPeriodMessage
            } else {
                finalMessage = message
            }

            // 알림 콘텐츠 설정
            let content = UNMutableNotificationContent()
            content.title = AppStrings.Notification.title
            content.body = finalMessage
            content.sound = .default
            content.badge = 1
            
            // 시간 컴포넌트 추출
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            
            // 매일 반복되는 트리거 생성
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            // 알림 요청 생성
            let request = UNNotificationRequest(
                identifier: self.notificationIdentifier,
                content: content,
                trigger: trigger
            )
            
            // 알림 등록
            self.notificationCenter.add(request) { error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                observer.onNext(())
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func checkAuthorizationStatus() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NotificationError.schedulingFailed)
                return Disposables.create()
            }
            
            self.notificationCenter.getNotificationSettings { settings in
                let isAuthorized = settings.authorizationStatus == .authorized
                observer.onNext(isAuthorized)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
}

protocol NotificationManagerProtocol {
    func requestAuthorization() -> Observable<Bool>
    func scheduleDailyNotification(at time: Date, isEnabled: Bool, message: String, cycle: Cycle?) -> Observable<Void>
    func cancelAllNotifications()
    func checkAuthorizationStatus() -> Observable<Bool>
}

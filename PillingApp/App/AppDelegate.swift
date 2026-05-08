import UIKit
import FirebaseCore
import FirebaseCrashlytics
import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        application.registerForRemoteNotifications()
        registerUserIfNeeded()

        #if DEBUG
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
        #else
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        #endif

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            Crashlytics.crashlytics().setCustomValue("\(version) (\(build))", forKey: "app_version")
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    // MARK: - APNs

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        let userID = resolveServerUserID()

        let registerUseCase = DIContainer.shared.makeRegisterUserUseCase()
        let updateTokenUseCase = DIContainer.shared.makeUpdateDeviceTokenUseCase()

        registerUseCase.execute(userID: userID, deviceToken: tokenString)
            .catch { error -> Observable<Void> in
                guard case PillingServerError.conflict = error else { return .just(()) }
                return updateTokenUseCase.execute(userID: userID, deviceToken: tokenString)
                    .catch { _ in .just(()) }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        DIContainer.shared.getCrashlyticsService().logError(error, userInfo: ["context": "APNs registration failed"])
    }

    // MARK: - Private

    private func registerUserIfNeeded() {
        let manager = DIContainer.shared.getUserDefaultsManager()
        guard manager.loadServerUserID() == nil else { return }
        let userID = resolveServerUserID()
        DIContainer.shared.makeRegisterUserUseCase()
            .execute(userID: userID, deviceToken: "")
            .catch { _ in .just(()) }
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func resolveServerUserID() -> String {
        let manager = DIContainer.shared.getUserDefaultsManager()
        if let existing = manager.loadServerUserID() { return existing }
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        manager.saveServerUserID(id)
        return id
    }
}

import UIKit
import IQKeyboardManagerSwift
import RxSwift

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private let disposeBag = DisposeBag()
    private let userDefaultsManager = DIContainer.shared.getUserDefaultsManager()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        configureIQKeyboardManager()

        DIContainer.shared.getAnalyticsService().logEvent(.appLaunched)

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        let crashlytics = DIContainer.shared.getCrashlyticsService()
        if let installID = UserDefaults.standard.string(forKey: "app_install_id") {
            crashlytics.setUserID(installID)
        } else {
            let newID = UUID().uuidString
            UserDefaults.standard.set(newID, forKey: "app_install_id")
            crashlytics.setUserID(newID)
        }
        crashlytics.setCustomValue(UIDevice.current.systemVersion, forKey: "ios_version")
        crashlytics.setCustomValue(UIDevice.current.model, forKey: "device_model")

        DIContainer.shared.getPillCycleRepository()
            .fetchCurrentCycle()
            .subscribe(onNext: { cycle in
                if let cycle = cycle {
                    crashlytics.setCustomValue(cycle.startDate.ISO8601Format(), forKey: "cycle_start_date")
                    crashlytics.setCustomValue(cycle.activeDays, forKey: "cycle_active_days")
                    crashlytics.setCustomValue(cycle.breakDays, forKey: "cycle_break_days")
                }
            })
            .disposed(by: disposeBag)

        if !userDefaultsManager.hasCompletedOnboarding() {
            showOnboarding()
            window.makeKeyAndVisible()
            return
        }

        startMainFlow()
    }
    
    private func configureIQKeyboardManager() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
    }

    private func startMainFlow() {
        let wasReset = VersionManager.shared.checkAndResetIfNeeded()

        if wasReset {
            showPillSetting()
            window?.makeKeyAndVisible()
            return
        }

        checkExistingCycle { hasExistingCycle in
            DispatchQueue.main.async {
                if hasExistingCycle {
                    self.showDashboard()
                } else {
                    self.showPillSetting()
                }

                self.window?.makeKeyAndVisible()
            }
        }
    }
    
    private func checkExistingCycle(completion: @escaping (Bool) -> Void) {
        let repository = DIContainer.shared.getPillCycleRepository()
        
        repository.fetchCurrentCycle()
            .subscribe(onNext: { cycle in
                completion(cycle != nil)
            }, onError: { _ in
                completion(false)
            })
            .disposed(by: disposeBag)
    }
    
    private func showDashboard() {
        let viewModel = DIContainer.shared.makeDashboardViewModel()
        let stasticsViewModel = DIContainer.shared.makeStasticsViewModel()
        let userDefaultsManager = DIContainer.shared.getUserDefaultsManager()
        let timeProvider = DIContainer.shared.timeProvider
        let dashboardVC = DashboardViewController(
            viewModel: viewModel,
            stasticsViewModel: stasticsViewModel,
            userDefaultsManager: userDefaultsManager,
            timeProvider: timeProvider
        )
        let navigationController = UINavigationController(rootViewController: dashboardVC)
        window?.rootViewController = navigationController
    }
    
    private func showPillSetting() {
        let viewModel = DIContainer.shared.makePillSettingViewModel()
        let pillSettingVC = PillSettingViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: pillSettingVC)
        navigationController.navigationBar.isHidden = false
        window?.rootViewController = navigationController
    }

    private func showOnboarding() {
        let onboardingVC = OnboardingViewController(
            userDefaultsManager: userDefaultsManager,
            onCompletion: { [weak self] in
                self?.startMainFlow()
            }
        )
        window?.rootViewController = onboardingVC
    }
    private func showTest() {
        let viewModel = DIContainer.shared.makeStasticsViewModel()
        let pillSettingVC = StasticsViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: pillSettingVC)
        navigationController.navigationBar.isHidden = false
        window?.rootViewController = navigationController
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        DIContainer.shared.getAnalyticsService().logEvent(.appForegrounded)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        DIContainer.shared.getAnalyticsService().logEvent(.appBackgrounded)
    }
}

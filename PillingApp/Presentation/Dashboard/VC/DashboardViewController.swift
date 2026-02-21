import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class DashboardViewController: UIViewController {
    
    // MARK: - ViewModels

    private let viewModel: DashboardViewModel
    private let stasticsViewModel: StatisticsViewModel
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let timeProvider: TimeProvider
    private let disposeBag = DisposeBag()

    // MARK: - Managers & Coordinators

    private lazy var coordinator = DashboardCoordinator(navigationController: navigationController)
    private lazy var sheetPresenter = DashboardSheetPresenter(
        viewController: self,
        userDefaultsManager: userDefaultsManager,
        timeProvider: timeProvider
    )
    private var transitionManager: DashboardViewTransitionManager?
    private var bindingManager: DashboardViewBindingManager?
    
    // MARK: - SubViews
    
    private let backgroundImageView = UIImageView(image: UIImage(named: "background_taken"))
    private let topButtonsView = DashboardTopButtonsView()
    private let infoView = DashboardMiddleView()
    private let stasticsView = StatisticsContentView()
    private let bottomView = DashboardBottomView()
    private let containerView = UIView()
    
    // MARK: - Properties
    
    var shouldHideHistoryButton: Bool = true {
        didSet {
            topButtonsView.isHistoryButtonHidden = shouldHideHistoryButton
        }
    }
    
    // MARK: - Initialization

    init(
        viewModel: DashboardViewModel,
        stasticsViewModel: StatisticsViewModel,
        userDefaultsManager: UserDefaultsManagerProtocol,
        timeProvider: TimeProvider
    ) {
        self.viewModel = viewModel
        self.stasticsViewModel = stasticsViewModel
        self.userDefaultsManager = userDefaultsManager
        self.timeProvider = timeProvider
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupConstraints()
        setupTransitionManager()
        setupBindingManager()
        setupAppLifecycleObserver()
        updateBackgroundForToday()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        infoView.updateCalendarLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        extendedLayoutIncludesOpaqueBars = true
        edgesForExtendedLayout = [.top, .left, .right, .bottom]
        
        viewModel.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DIContainer.shared.getAnalyticsService().logEvent(.screenViewed(screenName: "Dashboard"))
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = AppColor.bg
        
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)
        
        view.addSubview(containerView)
        
        containerView.addSubview(infoView)
        containerView.addSubview(stasticsView)
        stasticsView.isHidden = true
        
        view.addSubview(bottomView)
        view.addSubview(topButtonsView)
        
        topButtonsView.isHistoryButtonHidden = shouldHideHistoryButton
    }
    
    private func setupConstraints() {
        DashboardViewLayout.setupConstraints(
            in: view,
            backgroundImageView: backgroundImageView,
            topButtonsView: topButtonsView,
            containerView: containerView,
            infoView: infoView,
            stasticsView: stasticsView,
            bottomView: bottomView
        )
    }
    
    private func setupTransitionManager() {
        transitionManager = DashboardViewTransitionManager(
            containerView: containerView,
            infoView: infoView,
            statisticsView: stasticsView
        )

        transitionManager?.onViewIndexChanged = { [weak self] index in
            self?.handleViewIndexChanged(index)
        }

        // 초기 페이지 컨트롤 상태 설정
        handleViewIndexChanged(.dashboard)
    }
    
    private func setupBindingManager() {
        bindingManager = DashboardViewBindingManager(
            viewModel: viewModel,
            stasticsViewModel: stasticsViewModel
        )
        
        bindingManager?.bindAll(
            infoView: infoView,
            bottomView: bottomView,
            topButtonsView: topButtonsView,
            stasticsView: stasticsView,
            coordinator: coordinator,
            sheetPresenter: sheetPresenter,
            onBackgroundUpdate: { [weak self] in
                self?.updateBackgroundForToday()
            },
            onRetryAlert: { [weak self] retryHandler in
                self?.presentRetryAlert(retryHandler: retryHandler)
            },
            onNewCycleAlert: { [weak self] in
                self?.presentNewCycleAlert()
            },
            onCompletionFloatingView: { [weak self] in
                self?.presentCompletionFloatingView()
            }
        )
    }

    private func presentNewCycleAlert() {
        let alert = UIAlertController(
            title: "새 약 설정하기",
            message: "사이클이 완료되었습니다.\n새로운 약을 설정하시겠습니까?",
            preferredStyle: .alert
        )

        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.coordinator.navigateToPillSetting()
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(cancelAction)
        alert.addAction(confirmAction)

        present(alert, animated: true)
    }

    private func presentCompletionFloatingView() {
        let pillName = viewModel.pillInfo.value?.name ?? "피임약"
        let floatingView = CycleCompleteFloatingView(pillName: pillName)

        floatingView.onStartNewCycle = { [weak self] in
            // Analytics: 새 약 시작하기 버튼 탭
            DIContainer.shared.getAnalyticsService().logEvent(.newCycleStarted)
            self?.coordinator.navigateToPillSetting()
        }

        floatingView.show(in: view)
    }

    private func presentRetryAlert(retryHandler: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "오류",
            message: "데이터를 불러오는데 실패했습니다.\n다시 시도하시겠습니까?",
            preferredStyle: .alert
        )

        let retryAction = UIAlertAction(title: "재시도", style: .default) { _ in
            DIContainer.shared.getAnalyticsService().logEvent(.retryButtonTapped)
            retryHandler()
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(cancelAction)
        alert.addAction(retryAction)

        present(alert, animated: true)
    }

    private func setupAppLifecycleObserver() {
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.viewModel.reloadData()
                self?.updateBackgroundForToday()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - UI Updates
    
    private func updateBackgroundForToday() {
        guard let message = viewModel.dashboardMessage.value else {
            backgroundImageView.image = UIImage(named: "background_rest")
            return
        }

        backgroundImageView.image = UIImage(named: message.backgroundImageName)
    }
    
    private func handleViewIndexChanged(_ index: DashboardViewTransitionManager.ViewIndex) {
        bottomView.pageControl.numberOfPages = 2
        bottomView.pageControl.currentPage = index.rawValue

        // shouldHideHistoryButton이 true면 항상 숨김, 아니면 statistics 뷰일 때만 숨김
        if shouldHideHistoryButton {
            topButtonsView.isHistoryButtonHidden = true
        } else {
            topButtonsView.isHistoryButtonHidden = (index == .statistics)
        }
    }
}

import UIKit
import SnapKit

struct OnboardingPageContent {
    let imageName: String?
    let title: String
    let description: String
}

final class OnboardingPageViewController: UIViewController {
    private let content: OnboardingPageContent

    private let imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.grayBackground
        view.clipsToBounds = true
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.headline1(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body2()
        label.textColor = AppColor.secondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(content: OnboardingPageContent) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupLayout()
        applyContent()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass ||
            previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
        }
    }

    private func setupLayout() {
        view.addSubview(imageContainer)
        imageContainer.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)

        imageContainer.snp.makeConstraints { make in
            make.top.horizontalEdges.equalToSuperview()
            make.height.equalTo(426)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(44)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }

    private func applyContent() {
        if let imageName = content.imageName, let image = UIImage(named: imageName) {
            imageView.image = image
        } else {
            imageView.image = nil
        }

        titleLabel.text = content.title.isEmpty ? " " : content.title
        descriptionLabel.text = content.description.isEmpty ? " " : content.description

        let deviceType = traitCollection.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        print("[Onboarding] device:\(deviceType) viewSize:\(view.bounds.size)")
    }
}

final class OnboardingViewController: UIViewController {
    private typealias Str = AppStrings.Onboarding
    private let contents: [OnboardingPageContent]
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let onCompletion: () -> Void
    private let analytics: AnalyticsServiceProtocol

    private lazy var pages: [OnboardingPageViewController] = {
        contents.map { OnboardingPageViewController(content: $0) }
    }()

    private lazy var pageViewController: UIPageViewController = {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageVC.dataSource = self
        pageVC.delegate = self
        return pageVC
    }()

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = AppColor.pillGreen700
        control.pageIndicatorTintColor = AppColor.pillGreen100
        control.isUserInteractionEnabled = false
        return control
    }()

    private let nextButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(Str.nextButton, for: .normal)
        return button
    }()

    private var currentIndex: Int = 0

    init(
        contents: [OnboardingPageContent] = OnboardingViewController.defaultContents(),
        userDefaultsManager: UserDefaultsManagerProtocol,
        onCompletion: @escaping () -> Void,
        analytics: AnalyticsServiceProtocol = DIContainer.shared.getAnalyticsService()
    ) {
        self.contents = contents
        self.userDefaultsManager = userDefaultsManager
        self.onCompletion = onCompletion
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.bg
        configurePageViewController()
        configureLayout()
        pageControl.numberOfPages = contents.count
        updatePageControl()
        updateButtonText()
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
        analytics.logEvent(.onboardingStarted)
    }

    private func configurePageViewController() {
        guard let first = pages.first else { return }
        pageViewController.setViewControllers([first], direction: .forward, animated: false)
    }

    private func configureLayout() {
        let pageContainer = UIView()
        pageContainer.backgroundColor = .clear
        view.addSubview(pageContainer)
        view.addSubview(pageControl)
        view.addSubview(nextButton)

        pageContainer.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(pageControl.snp.top).offset(-24)
        }

        pageControl.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(nextButton.snp.top).offset(-16)
        }

        nextButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
        }

        guard let pageView = pageViewController.view else { return }
        addChild(pageViewController)
        pageContainer.addSubview(pageView)
        pageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        pageViewController.didMove(toParent: self)
    }

    @objc
    private func didTapNext() {
        if currentIndex < pages.count - 1 {
            moveToPage(currentIndex + 1)
        } else {
            completeOnboarding()
        }
    }

    private func moveToPage(_ index: Int) {
        guard index >= 0 && index < pages.count else { return }
        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        currentIndex = index
        pageViewController.setViewControllers([pages[index]], direction: direction, animated: true)
        updatePageControl()
    }

    private func updatePageControl() {
        pageControl.currentPage = currentIndex
        updateButtonText()
    }

    private func updateButtonText() {
        let isLastPage = currentIndex == pages.count - 1
        let buttonTitle = isLastPage ? Str.startButton : Str.nextButton
        nextButton.setTitle(buttonTitle, for: .normal)
    }

    private func completeOnboarding() {
        analytics.logEvent(.onboardingCompleted)
        userDefaultsManager.setHasCompletedOnboarding(true)
        onCompletion()
    }

    static func defaultContents() -> [OnboardingPageContent] {
        [
            OnboardingPageContent(
                imageName: "onboarding_1",
                title: Str.page1Title,
                description: Str.page1Description
            ),
            OnboardingPageContent(
                imageName: "onboarding_2",
                title: Str.page2Title,
                description: Str.page2Description
            ),
            OnboardingPageContent(
                imageName: "onboarding_3",
                title: Str.page3Title,
                description: Str.page3Description
            )
        ]
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }) else { return nil }
        let previousIndex = index - 1
        guard previousIndex >= 0 else { return nil }
        return pages[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(where: { $0 === viewController }) else { return nil }
        let nextIndex = index + 1
        guard nextIndex < pages.count else { return nil }
        return pages[nextIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let visible = pageViewController.viewControllers?.first,
              let index = pages.firstIndex(where: { $0 === visible }) else { return }
        currentIndex = index
        updatePageControl()
        analytics.logEvent(.onboardingStepCompleted(step: currentIndex))
    }
}

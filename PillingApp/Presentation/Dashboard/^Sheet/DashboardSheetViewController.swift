import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - DashboardSheetViewController
final class DashboardSheetViewController: UIViewController {
    
    // MARK: - Properties
    
    private let onDataChanged: (PillStatus?, String) -> Void
    private let onTimeChanged: ((Date) -> Void)?
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let timeProvider: TimeProvider
    private let disposeBag = DisposeBag()
    private var initialSideEffectIds: [String] = []
    
    var titleText: String?
    
    private typealias str = AppStrings.Dashboard
    
    // MARK: - Components
    
    private lazy var sheetAnimator = DashboardSheetAnimator(
        viewController: self,
        sheetHeight: 420
    )
    
    private let statusSelectionView = StatusSelectionView()
    
    private lazy var sideEffectTagsView = SideEffectTagsView(
        userDefaultsManager: userDefaultsManager
    )
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isUserInteractionEnabled = true
        scrollView.delaysContentTouches = false
        return scrollView
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textBlack
        return label
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.isUserInteractionEnabled = true
        return stack
    }()
    
    private let timeSettingButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: AppStrings.Setting.timeSettingTitle, iconSystemName: "clock")
        return button
    }()
    
    // MARK: - ViewModel & Relays
    
    private let viewModel: DefaultDashboardSheetViewModel
    private let requestDismissRelay = PublishRelay<Void>()
    private let timeChangedRelay = PublishRelay<Date>()
    
    // MARK: - Initialization
    
    init(
        selectedDate: Date,
        initialMemo: String = "",
        takenAt: Date? = nil,
        initialStatus: PillStatus? = nil,
        userDefaultsManager: UserDefaultsManagerProtocol,
        timeProvider: TimeProvider,
        onDataChanged: @escaping (PillStatus?, String) -> Void,
        onTimeChanged: ((Date) -> Void)? = nil
    ) {
        self.onDataChanged = onDataChanged
        self.onTimeChanged = onTimeChanged
        self.userDefaultsManager = userDefaultsManager
        self.timeProvider = timeProvider

        // 초기 메모에서 부작용 태그 파싱
        let parsedMemo = PillRecordMemo.fromJSONString(initialMemo)
        self.initialSideEffectIds = parsedMemo.sideEffectIds

        print("🔍 [DashboardSheet] init - initialMemo: \(initialMemo)")
        print("🔍 [DashboardSheet] init - parsedMemo.sideEffectIds: \(parsedMemo.sideEffectIds)")
        print("🔍 [DashboardSheet] init - parsedMemo.text: \(parsedMemo.text)")

        self.viewModel = DefaultDashboardSheetViewModel(
            selectedDate: selectedDate,
            initialMemo: parsedMemo.text,
            initialStatus: initialStatus,
            takenAt: takenAt
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupGestures()
        bindComponents()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 🔍 DEBUG: 부작용 초기화 상태 로깅
        print("🔍 [DashboardSheet] viewWillAppear - initialSideEffectIds: \(initialSideEffectIds)")
        print("🔍 [DashboardSheet] viewWillAppear - before setSelectedTagIds: \(sideEffectTagsView.getSelectedTagIds())")

        // 부작용 관리에서 돌아올 때를 대비해 태그 목록을 다시 로드
        // (태그 추가/삭제/순서변경/visibility 변경 반영)
        sideEffectTagsView.reloadTags()

        // 🔧 FIX: 초기 부작용 선택 상태 복원
        sideEffectTagsView.setSelectedTagIds(initialSideEffectIds)

        print("🔍 [DashboardSheet] viewWillAppear - after setSelectedTagIds: \(sideEffectTagsView.getSelectedTagIds())")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    
    // MARK: - Setup

    private func formatTitleText(_ text: String) -> NSAttributedString {
        // "3일차/28" 형식을 파싱
        let components = text.components(separatedBy: "/")

        let attributedString = NSMutableAttributedString()

        if components.count == 2 {
            // "n일차" 부분: size 28, bold
            let dayPart = NSAttributedString(
                string: components[0],
                attributes: [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: AppColor.textBlack
                ]
            )

            // "/28" 부분: size 20, regular
            let totalPart = NSAttributedString(
                string: "/" + components[1],
                attributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .regular),
                    .foregroundColor: AppColor.textBlack
                ]
            )

            attributedString.append(dayPart)
            attributedString.append(totalPart)
        } else {
            // 파싱 실패 시 기본 스타일
            return NSAttributedString(
                string: text,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                    .foregroundColor: AppColor.textBlack
                ]
            )
        }

        return attributedString
    }

    private func setupViews() {
        view.backgroundColor = .clear

        sheetAnimator.setupViews(in: view)

        sheetAnimator.containerView.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // titleText를 파싱해서 attributed string으로 설정
        if let titleText = titleText ?? title {
            subtitleLabel.attributedText = formatTitleText(titleText)
        }

        // StatusSelectionView의 터치 이벤트 활성화
        statusSelectionView.isUserInteractionEnabled = true

        contentStackView.addArrangedSubview(subtitleLabel)
        contentStackView.addArrangedSubview(statusSelectionView)
        contentStackView.addArrangedSubview(timeSettingButton)
        contentStackView.addArrangedSubview(sideEffectTagsView)

        setupConstraints()
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(sheetAnimator.handleBar.snp.bottom).offset(0)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
            make.width.equalTo(scrollView).inset(24)
        }
        
        timeSettingButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }
    
    private func setupGestures() {
        let dimmedTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmedViewTap))
        sheetAnimator.dimmedView.addGestureRecognizer(dimmedTapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGesture.cancelsTouchesInView = false  // 🔧 하위 뷰의 터치를 방해하지 않도록 설정
        panGesture.delegate = self
        sheetAnimator.containerView.addGestureRecognizer(panGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Component Binding
    
    private func bindComponents() {
        sideEffectTagsView.addButtonTapped
            .subscribe(onNext: { [weak self] in
                self?.presentSideEffectManagement()
            })
            .disposed(by: disposeBag)
        
        timeSettingButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.presentTimePickerBottomSheet()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - ViewModel Binding
    
    private func bindViewModel() {
        let input = DashboardSheetViewModelInput(
            viewDidAppear: rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
                .map { _ in () }
                .take(1),
            tapNotTaken: statusSelectionView.notTakenTapped.asObservable(),
            tapTaken: statusSelectionView.takenTapped.asObservable(),
            tapTakenDouble: statusSelectionView.takenDoubleTapped.asObservable(),
            memoText: Observable.just(""),
            requestDismiss: requestDismissRelay.asObservable(),
            timeChanged: timeChangedRelay.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        output.shouldShowSheet
            .emit(onNext: { [weak self] in
                self?.sheetAnimator.show()
            })
            .disposed(by: disposeBag)
        
        output.initialButtonTag
            .drive(onNext: { [weak self] buttonTag in
                self?.statusSelectionView.setInitialSelection(buttonTag: buttonTag)
            })
            .disposed(by: disposeBag)
        
        output.formattedTime
            .drive(onNext: { [weak self] timeString in
                self?.timeSettingButton.setValue(timeString)
            })
            .disposed(by: disposeBag)
        
        //        output.isMemoPlaceholderHidden
        //            .drive()
        //            .disposed(by: disposeBag)
        //
        output.dismiss
            .emit(onNext: { [weak self] status, memoText in
                guard let self else { return }

                // 선택된 부작용 태그 ID 수집
                let selectedTagIds = self.sideEffectTagsView.getSelectedTagIds()

                print("🔍 [DashboardSheet] dismiss - selectedTagIds: \(selectedTagIds)")

                // 선택된 태그의 이름을 함께 저장 (삭제된 태그 대비)
                let allTags = self.userDefaultsManager.loadSideEffectTags()

                let selectedTags = allTags.filter { selectedTagIds.contains($0.id) }

                let sideEffectNames = Dictionary(uniqueKeysWithValues: selectedTags.map { ($0.id, $0.name) })

                // PillRecordMemo로 결합하여 JSON 저장
                let pillMemo = PillRecordMemo(
                    text: memoText,
                    sideEffectIds: selectedTagIds,
                    sideEffectNames: sideEffectNames.isEmpty ? nil : sideEffectNames
                )
                let memoJSON = pillMemo.toJSONString()

                print("🔍 [DashboardSheet] dismiss - memoJSON: \(memoJSON)")

                self.onDataChanged(status, memoJSON)
                self.sheetAnimator.hide()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handleDimmedViewTap() {
        requestDismissRelay.accept(())
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        sheetAnimator.handlePanGesture(gesture) { [weak self] in
            self?.requestDismissRelay.accept(())
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Time Picker
    
    private func presentTimePickerBottomSheet() {
        let timePickerSheet = TimePickerBottomSheet(initialTime: timeProvider.now)
        
        timePickerSheet.selectedTime
            .take(1)
            .subscribe(onNext: { [weak self] selectedTime in
                guard let self = self else { return }
                self.timeChangedRelay.accept(selectedTime)
                self.onTimeChanged?(selectedTime)
            })
            .disposed(by: disposeBag)
        
        present(timePickerSheet, animated: false)
    }
    
    // MARK: - Navigation
    
    private func presentSideEffectManagement() {
        let managementVC = SideEffectManagementViewController(userDefaultsManager: userDefaultsManager)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.pushViewController(managementVC, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension DashboardSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Pan gesture와 다른 제스처(버튼 탭 등)를 동시에 인식하도록 허용
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 버튼이나 인터랙티브한 뷰를 터치한 경우 Pan gesture가 터치를 받지 않도록 함
        if touch.view is UIButton || touch.view is UIControl {
            return false
        }
        return true
    }
}

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import IQKeyboardManagerSwift

// MARK: - PillTypeBottomSheetViewController

final class PillTypeBottomSheetViewController: UIViewController {
    
    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private let selectedPillInfo = PublishSubject<PillInfo>()
    private typealias str = AppStrings.PillSetting
    var pillInfoSelected: Observable<PillInfo> {
        return selectedPillInfo.asObservable()
    }

    private let medicationRepository: MedicationRepositoryProtocol
    private let searchResultsRelay = BehaviorRelay<[MedicationInfo]>(value: [])
    private let initialMedicationsRelay = BehaviorRelay<[MedicationInfo]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: true)
    private let initialSearchKeywords = ["머시론","센스데이","멜리안","마이보라","야즈","야스민"]
    private let contraceptiveTypeKeyword = "피임제"
    private var selectedMedicationId: String?
    
    // MARK: - UI Components
    
    private let dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()
    
    private let handleBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.85, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let pillNameTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.borderStyle = .none
        textField.backgroundColor = UIColor(hex: "#F7F7F7")
        textField.layer.cornerRadius = 20

        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        textField.leftView = leftPaddingView
        textField.leftViewMode = .always

        let searchIconImageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIconImageView.tintColor = .lightGray
        searchIconImageView.contentMode = .scaleAspectFit
        let rightContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 50))
        searchIconImageView.frame = CGRect(x: 0, y: 15, width: 20, height: 20)
        rightContainerView.addSubview(searchIconImageView)
        textField.rightView = rightContainerView
        textField.rightViewMode = .always

        return textField
    }()
    
    private let confirmButton = PrimaryActionButton()

    private let searchResultsTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.isHidden = false
        tableView.register(MedicationSearchTableViewCell.self, forCellReuseIdentifier: MedicationSearchTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
        return tableView
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private var containerViewBottomConstraint: Constraint?
    
    // MARK: - Initialization

    init(medicationRepository: MedicationRepositoryProtocol = DIContainer.shared.getMedicationRepository()) {
        self.medicationRepository = medicationRepository
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
        IQKeyboardManager.shared.keyboardDistance = 60
        setupUI()
        setupConstraints()
        bind()
        setupGestures()
        fetchInitialMedications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatePresentation()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(dimmedView)
        view.addSubview(containerView)

        containerView.addSubview(handleBar)
        containerView.addSubview(pillNameTextField)
        containerView.addSubview(confirmButton)
        containerView.addSubview(searchResultsTableView)
        containerView.addSubview(loadingIndicator)
        confirmButton.setTitle(str.settingComplete, for: .normal)
        confirmButton.isEnabled = false
    }
    
    private func setupConstraints() {
        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(500)
            containerViewBottomConstraint = $0.bottom.equalTo(view.snp.bottom).offset(500).constraint
        }

        handleBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }

        pillNameTextField.snp.makeConstraints {
            $0.top.equalTo(handleBar.snp.bottom).offset(24)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(342)
            $0.height.equalTo(50)
        }

        searchResultsTableView.snp.makeConstraints {
            $0.top.equalTo(pillNameTextField.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(0)
            $0.bottom.equalTo(confirmButton.snp.top).offset(-24)
        }

        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().offset(-20)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(searchResultsTableView.snp.centerY)
        }
    }
    
    
    private func bind() {
        confirmButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self,
                      let selectedId = self.selectedMedicationId else { return }

                let medications = self.searchResultsRelay.value
                if let medication = medications.first(where: { ($0.id.isEmpty ? $0.name : $0.id) == selectedId }) {
                    let pillInfo = medication.toPillInfo()
                    self.selectedPillInfo.onNext(pillInfo)
                    self.dismissBottomSheet()
                }
            })
            .disposed(by: disposeBag)

        pillNameTextField.rx.text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { [weak self] keyword -> Observable<[MedicationInfo]> in
                guard let self = self else {
                    return Observable.just([])
                }

                let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedKeyword.isEmpty {
                    self.isLoadingRelay.accept(false)
                    return self.initialMedicationsRelay.asObservable()
                }

                guard trimmedKeyword.count >= 2 else {
                    self.isLoadingRelay.accept(false)
                    return Observable.just([])
                }
                self.isLoadingRelay.accept(true)
                return self.medicationRepository.searchMedication(keyword: trimmedKeyword)
                    .do(onNext: { [weak self] _ in
                        self?.isLoadingRelay.accept(false)
                    }, onError: { [weak self] _ in
                        self?.isLoadingRelay.accept(false)
                    }, onCompleted: { [weak self] in
                        self?.isLoadingRelay.accept(false)
                    })
                    .catch { error in
                        print("검색 에러: \(error.localizedDescription)")
                        return Observable.just([])
                    }
            }
            .map { [weak self] results -> [MedicationInfo] in
                guard let self = self else { return results }
                return results.filter { $0.productTypeDisplay.contains(self.contraceptiveTypeKeyword) }
            }
            .observe(on: MainScheduler.instance)
            .bind(to: searchResultsRelay)
            .disposed(by: disposeBag)

        isLoadingRelay
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                guard let self = self else { return }
                isLoading ? self.loadingIndicator.startAnimating() : self.loadingIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)

        searchResultsRelay
            .bind(to: searchResultsTableView.rx.items(
                cellIdentifier: MedicationSearchTableViewCell.identifier,
                cellType: MedicationSearchTableViewCell.self
            )) { [weak self] index, medication, cell in
                guard let self = self else { return }
                let medicationId = medication.id.isEmpty ? medication.name : medication.id
                let isSelected = self.selectedMedicationId == medicationId
                cell.configure(with: medication, isSelected: isSelected)
            }
            .disposed(by: disposeBag)

        searchResultsTableView.rx.modelSelected(MedicationInfo.self)
            .subscribe(onNext: { [weak self] medication in
                guard let self = self else { return }
                let medicationId = medication.id.isEmpty ? medication.name : medication.id
                self.selectedMedicationId = medicationId
                self.confirmButton.isEnabled = true
                self.searchResultsTableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func fetchInitialMedications() {
        isLoadingRelay.accept(true)
        Observable.from(initialSearchKeywords)
            .concatMap { [weak self] keyword -> Observable<[MedicationInfo]> in
                guard let self = self else { return Observable.just([]) }
                return self.medicationRepository.searchMedication(keyword: keyword)
                    .catch { _ in Observable.just([]) }
            }
            .toArray()
            .map { resultsByKeyword -> [MedicationInfo] in
                var uniqueById: [String: MedicationInfo] = [:]
                for medications in resultsByKeyword {
                    for medication in medications where medication.productTypeDisplay.contains(self.contraceptiveTypeKeyword) {
                        let key = medication.id.isEmpty ? medication.name : medication.id
                        if uniqueById[key] == nil {
                            uniqueById[key] = medication
                        }
                    }
                }
                return Array(uniqueById.values).sorted { $0.name < $1.name }
            }
            .asObservable()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] results in
                guard let self = self else { return }
                self.initialMedicationsRelay.accept(results)
                if self.pillNameTextField.text?.isEmpty ?? true {
                    self.searchResultsRelay.accept(results)
                }
                self.isLoadingRelay.accept(false)
            }, onError: { error in
                print("초기 목록 에러: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer()
        dimmedView.addGestureRecognizer(tapGesture)
        
        tapGesture.rx.event
            .subscribe(onNext: { [weak self] _ in
                self?.dismissBottomSheet()
            })
            .disposed(by: disposeBag)
        
        let panGesture = UIPanGestureRecognizer()
        containerView.addGestureRecognizer(panGesture)
        
        panGesture.rx.event
            .subscribe(onNext: { [weak self] gesture in
                self?.handlePanGesture(gesture)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private func animatePresentation() {
        containerViewBottomConstraint?.update(offset: 0)
        
        UIView.animate(
            withDuration: DatePickerConfiguration.Animation.presentationDuration,
            delay: 0,
            usingSpringWithDamping: DatePickerConfiguration.Animation.springDamping,
            initialSpringVelocity: DatePickerConfiguration.Animation.springVelocity,
            options: .curveEaseOut
        ) {
            self.dimmedView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    private func dismissBottomSheet() {
        view.endEditing(true)

        containerViewBottomConstraint?.update(offset: 500)

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.dimmedView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
    private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerViewBottomConstraint?.update(offset: translation.y)
            }
        case .ended:
            if translation.y > 100 || velocity.y > 500 {
                dismissBottomSheet()
            } else {
                containerViewBottomConstraint?.update(offset: 0)
                UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
                    self.view.layoutIfNeeded()
                }
            }
        default:
            break
        }
    }
}

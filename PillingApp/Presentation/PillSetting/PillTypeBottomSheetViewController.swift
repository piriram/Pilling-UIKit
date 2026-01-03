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
    
    private let takingDaysOptions = Array(1...31)
    private let breakDaysOptions = Array(0...14)
    
    private var selectedTakingDays = 24
    private var selectedBreakDays = 4
    
    private let selectedTakingDaysRelay = BehaviorRelay<Int>(value: 24)
    private let selectedBreakDaysRelay = BehaviorRelay<Int>(value: 4)
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = str.titleLabel
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let pillNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = str.nameTitle
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.borderStyle = .none
        textField.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        return textField
    }()
    
    private let takingDaysLabel: UILabel = {
        let label = UILabel()
        label.text = str.takingDays
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let takingDaysButton: UIButton = {
        let button = UIButton()
        button.setTitle(str.takingBtn, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .center
        return button
    }()
    
    private let breakDaysLabel: UILabel = {
        let label = UILabel()
        label.text = str.breakLabel
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let breakDaysButton: UIButton = {
        let button = UIButton()
        button.setTitle(str.breakDay, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        button.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .center
        return button
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = str.warningLabel
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        label.textAlignment = .natural
        return label
    }()
    
    private let pickerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private let pickerToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.backgroundColor = .white
        toolbar.barTintColor = .white
        return toolbar
    }()
    
    private let pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.backgroundColor = .white
        return picker
    }()
    
    private let confirmButton = PrimaryActionButton()
    
    private var containerViewBottomConstraint: Constraint?
    private var currentPickerType: PickerType = .takingDays
    
    private enum PickerType {
        case takingDays
        case breakDays
    }
    
    // MARK: - Initialization
    
    init() {
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
        setupPickerView()
        bind()
        setupGestures()
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
        containerView.addSubview(titleLabel)
        containerView.addSubview(pillNameTextField)
        containerView.addSubview(takingDaysLabel)
        containerView.addSubview(takingDaysButton)
        containerView.addSubview(breakDaysLabel)
        containerView.addSubview(breakDaysButton)
        containerView.addSubview(warningLabel)
        containerView.addSubview(confirmButton)
        confirmButton.setTitle(str.settingComplete, for: .normal)
        
        selectedTakingDaysRelay.accept(selectedTakingDays)
        selectedBreakDaysRelay.accept(selectedBreakDays)
        
        view.addSubview(pickerContainerView)
        pickerContainerView.addSubview(pickerToolbar)
        pickerContainerView.addSubview(pickerView)
    }
    
    private func setupConstraints() {
        dimmedView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        containerView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(460)
            containerViewBottomConstraint = $0.bottom.equalTo(view.snp.bottom).offset(460).constraint
        }
        
        handleBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(12)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(handleBar.snp.bottom).offset(20)
            $0.leading.equalToSuperview().offset(24)
        }
        
        pillNameTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(52)
        }
        
        takingDaysLabel.snp.makeConstraints {
            $0.top.equalTo(pillNameTextField.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(24)
        }
        
        takingDaysButton.snp.makeConstraints {
            $0.top.equalTo(takingDaysLabel.snp.bottom).offset(12)
            $0.leading.equalToSuperview().offset(24)
            $0.width.equalTo(140)
            $0.height.equalTo(52)
        }
        
        breakDaysLabel.snp.makeConstraints {
            $0.top.equalTo(pillNameTextField.snp.bottom).offset(24)
            $0.trailing.equalToSuperview().offset(-24)
        }
        
        breakDaysButton.snp.makeConstraints {
            $0.top.equalTo(breakDaysLabel.snp.bottom).offset(12)
            $0.trailing.equalToSuperview().offset(-24)
            $0.width.equalTo(140)
            $0.height.equalTo(52)
        }
        
        warningLabel.snp.makeConstraints {
            $0.top.equalTo(breakDaysButton.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(24)
        }
        
        confirmButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(56)
        }
        
        pickerContainerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(260)
        }
        
        pickerToolbar.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(44)
        }
        
        pickerView.snp.makeConstraints {
            $0.top.equalTo(pickerToolbar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupPickerView() {
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // 기본값 설정
        if let takingIndex = takingDaysOptions.firstIndex(of: selectedTakingDays) {
            pickerView.selectRow(takingIndex, inComponent: 0, animated: false)
        }
        if let breakIndex = breakDaysOptions.firstIndex(of: selectedBreakDays) {
            pickerView.selectRow(breakIndex, inComponent: 0, animated: false)
        }
        
        takingDaysButton.setTitle(AppStrings.PillSetting.daysFormat(selectedTakingDays), for: .normal)
        breakDaysButton.setTitle(AppStrings.PillSetting.daysFormat(selectedBreakDays), for: .normal)
        
        let doneButton = UIBarButtonItem(
            title: AppStrings.Common.confirmTitle,
            style: .done,
            target: self,
            action: #selector(pickerDoneButtonTapped)
        )
        let cancelButton = UIBarButtonItem(
            title: AppStrings.Common.cancelTitle,
            style: .plain,
            target: self,
            action: #selector(pickerCancelButtonTapped)
        )
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        pickerToolbar.items = [cancelButton, flexibleSpace, doneButton]
    }
    
    private func bind() {
        Observable
            .combineLatest(selectedTakingDaysRelay.asObservable(), selectedBreakDaysRelay.asObservable())
            .map { taking, breaking in (taking + breaking) <= 28 }
            .bind(to: confirmButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(selectedTakingDaysRelay.asObservable(), selectedBreakDaysRelay.asObservable())
            .map { taking, breaking in !((taking + breaking) > 28) }
            .bind(to: warningLabel.rx.isHidden)
            .disposed(by: disposeBag)
        
        takingDaysButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showPicker(for: .takingDays)
            })
            .disposed(by: disposeBag)
        
        breakDaysButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showPicker(for: .breakDays)
            })
            .disposed(by: disposeBag)
        
        confirmButton.rx.tap
            .withLatestFrom(pillNameTextField.rx.text.orEmpty)
            .map { [weak self] name -> PillInfo in
                guard let self = self else {
                    return PillInfo(name: name, takingDays: 24, breakDays: 4)
                }
                return PillInfo(
                    name: name,
                    takingDays: self.selectedTakingDays,
                    breakDays: self.selectedBreakDays
                )
            }
            .subscribe(onNext: { [weak self] pillInfo in
                guard let self = self else { return }
                // Emit selected pill info
                self.selectedPillInfo.onNext(pillInfo)
                // Only dismiss the bottom sheet; do not navigate
                self.dismissBottomSheet()
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
    
    private func showPicker(for type: PickerType) {
        currentPickerType = type
        pillNameTextField.resignFirstResponder()
        
        // 피커 데이터 리로드 및 현재 선택값으로 이동
        pickerView.reloadAllComponents()
        
        switch type {
        case .takingDays:
            if let index = takingDaysOptions.firstIndex(of: selectedTakingDays) {
                pickerView.selectRow(index, inComponent: 0, animated: false)
            }
        case .breakDays:
            if let index = breakDaysOptions.firstIndex(of: selectedBreakDays) {
                pickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
        
        pickerContainerView.isHidden = false
        pickerContainerView.transform = CGAffineTransform(translationX: 0, y: 260)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.pickerContainerView.transform = .identity
        }
    }
    
    private func hidePicker() {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.pickerContainerView.transform = CGAffineTransform(translationX: 0, y: 260)
        } completion: { _ in
            self.pickerContainerView.isHidden = true
        }
    }
    
    @objc private func pickerDoneButtonTapped() {
        hidePicker()
    }
    
    @objc private func pickerCancelButtonTapped() {
        hidePicker()
    }
    
    private func animatePresentation() {
        containerViewBottomConstraint?.update(offset: 0)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimmedView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    private func dismissBottomSheet() {
        view.endEditing(true)
        hidePicker()
        
        containerViewBottomConstraint?.update(offset: 460)
        
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

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource

extension PillTypeBottomSheetViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch currentPickerType {
        case .takingDays:
            return takingDaysOptions.count
        case .breakDays:
            return breakDaysOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch currentPickerType {
        case .takingDays:
            return AppStrings.PillSetting.daysFormat(takingDaysOptions[row])
        case .breakDays:
            return AppStrings.PillSetting.daysFormat(breakDaysOptions[row])
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch currentPickerType {
        case .takingDays:
            selectedTakingDays = takingDaysOptions[row]
            takingDaysButton.setTitle(AppStrings.PillSetting.daysFormat(selectedTakingDays), for: .normal)
            selectedTakingDaysRelay.accept(selectedTakingDays)
        case .breakDays:
            selectedBreakDays = breakDaysOptions[row]
            breakDaysButton.setTitle(AppStrings.PillSetting.daysFormat(selectedBreakDays), for: .normal)
            selectedBreakDaysRelay.accept(selectedBreakDays)
        }
    }
}

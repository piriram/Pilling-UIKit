import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class PillSettingViewController: UIViewController {

    // MARK: - Properties
    private typealias str = AppStrings.PillSetting
    private let viewModel: PillSettingViewModel
    private let disposeBag = DisposeBag()
    private let medicationRepository: MedicationRepositoryProtocol
    private let prefetchKeywords = ["머시론","센스데이","멜리안","마이보라","야즈","야스민"]
    
    // MARK: - UI Components
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "PillSetting")
        return imageView
    }()
    
    private let mainTitleLabel: UILabel = {
        let label = UILabel()
        label.text = str.mainTitle
        label.font = Typography.headline3(.bold)
        label.textColor = AppColor.textBlack
        label.textAlignment = .natural
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = str.subtitle
        label.font = Typography.body2(.regular)
        label.textColor = .gray
        label.textAlignment = .natural
        return label
    }()
    
    private let pillTypeButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: str.btnTitle, iconSystemName: "pills")
        return button
    }()
    
    private let currentDaysButton: SettingItemButton = {
        let button = SettingItemButton()
        button.configure(title: str.ctnBtnTitle, iconSystemName: "calendar")
        return button
    }()
    
    private let nextButton: PrimaryActionButton = {
        let button = PrimaryActionButton()
        button.setTitle(str.nextBtnTitle, for: .normal)
        button.isEnabled = false
        return button
    }()
    
    // MARK: - Initialization
    
    init(viewModel: PillSettingViewModel, medicationRepository: MedicationRepositoryProtocol = DIContainer.shared.getMedicationRepository()) {
        self.viewModel = viewModel
        self.medicationRepository = medicationRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureNavigationBar()
        bind()
        prefetchMedicationList()
        setupDebugGesture()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(iconImageView)
        view.addSubview(mainTitleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(pillTypeButton)
        view.addSubview(currentDaysButton)
        view.addSubview(nextButton)
    }
    
    private func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(0)
            $0.centerX.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(200)
        }
        
        mainTitleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(mainTitleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        pillTypeButton.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(48)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(60)
        }
        
        currentDaysButton.snp.makeConstraints {
            $0.top.equalTo(pillTypeButton.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(60)
        }
        
        nextButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            $0.height.equalTo(70)
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.title = ""
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.hidesBackButton = false
        navigationItem.backButtonDisplayMode = .default
    }
    
    private func bind() {
        // Input
        pillTypeButton.rx.tap
            .bind(to: viewModel.input.pillTypeButtonTapped)
            .disposed(by: disposeBag)
        
        currentDaysButton.rx.tap
            .bind(to: viewModel.input.startDateButtonTapped)
            .disposed(by: disposeBag)
        
        nextButton.rx.tap
            .bind(to: viewModel.input.nextButtonTapped)
            .disposed(by: disposeBag)
        
        // Output
        viewModel.output.selectedPillTypeText
            .drive(onNext: { [weak self] text in
                self?.pillTypeButton.setValue(text)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.selectedStartDateText
            .drive(onNext: { [weak self] dateText in
                self?.currentDaysButton.setValue(dateText)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.isNextButtonEnabled
            .drive(nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.output.presentDatePicker
            .emit(onNext: { [weak self] in
                self?.presentDatePickerBottomSheet()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.presentPillTypePicker
            .emit(onNext: { [weak self] in
                self?.presentPillTypeBottomSheet()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.proceed
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                let vm = DIContainer.shared.makeTimeSettingViewModel()
                let nextVC = TimeSettingViewController(viewModel: vm)
                if let nav = self.navigationController {
                    nav.pushViewController(nextVC, animated: true)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.alertMessage
            .emit(onNext: { [weak self] message in
                self?.presentNotification(message: message)
            })
            .disposed(by: disposeBag)
    }
    
    private func prefetchMedicationList() {
        Observable.from(prefetchKeywords)
            .concatMap { [weak self] keyword -> Observable<Void> in
                guard let self = self else { return Observable.just(()) }
                return self.medicationRepository.searchMedication(keyword: keyword)
                    .map { _ in () }
                    .catch { _ in Observable.just(()) }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func printHardcodedDataTemplate(_ medications: [String: [MedicationInfo]]) {
        print("\n" + String(repeating: "=", count: 80))
        print("📋 [Hardcoded Data Template] 아래 코드를 MedicationRepository.getHardcodedPills()에 복사하세요")
        print(String(repeating: "=", count: 80) + "\n")

        var hardcodedArray: [String] = []

        for keyword in prefetchKeywords {
            guard let meds = medications[keyword], !meds.isEmpty else {
                print("❌ '\(keyword)' - 데이터 없음")
                continue
            }

            // 피임제 타입만 선택
            let contraceptives = meds.filter { $0.productType.contains("[02540]") }

            guard let med = contraceptives.first else {
                print("⚠️ '\(keyword)' - 피임제 없음 (검색 결과: \(meds.count)개)")
                for m in meds {
                    print("   - \(m.name) [\(m.productType)]")
                }
                continue
            }

            // 데이터 완성도 체크
            var warnings: [String] = []
            if med.mainIngredient.isEmpty { warnings.append("성분 누락") }
            if med.dosageInstructions.isEmpty { warnings.append("용법 누락") }
            if med.packUnit.isEmpty { warnings.append("포장단위 누락") }
            if med.imageURL.isEmpty { warnings.append("이미지 누락") }

            let template = """
            MedicationInfo(
                id: "\(med.id)",
                name: "\(med.name)",
                manufacturer: "\(med.manufacturer)",
                mainIngredient: "\(med.mainIngredient)",
                materialName: "\(med.materialName)",
                dosageInstructions: "\(med.dosageInstructions)",
                packUnit: "\(med.packUnit)",
                storageMethod: "\(med.storageMethod)",
                permitDate: "\(med.permitDate)",
                imageURL: "\(med.imageURL)",
                productType: "\(med.productType)"
            )
            """

            hardcodedArray.append(template)

            print("✅ '\(keyword)' → \(med.name)")
            print("   제조사: \(med.manufacturer)")
            print("   ID: \(med.id)")
            print("   제품타입: \(med.productType)")
            if !med.mainIngredient.isEmpty {
                print("   성분: \(med.mainIngredient)")
            }
            if !med.dosageInstructions.isEmpty {
                print("   용법: \(med.dosageInstructions)")
            }
            if !med.imageURL.isEmpty {
                print("   이미지: ✓")
            }
            if !warnings.isEmpty {
                print("   ⚠️ 주의: \(warnings.joined(separator: ", "))")
            }
            print()
        }

        print("\n// Copy this code:")
        print("private static func getHardcodedPills() -> [MedicationInfo] {")
        print("    return [")
        print(hardcodedArray.joined(separator: ",\n"))
        print("    ]")
        print("}")
        print("\n" + String(repeating: "=", count: 80) + "\n")
    }
    
    // MARK: - Private Methods
    private func presentDatePickerBottomSheet() {
        let datePickerVC = DatePickerBottomSheetViewController()
        
        datePickerVC.selectedDate
            .emit(to: viewModel.input.dateSelected)
            .disposed(by: disposeBag)
        
        present(datePickerVC, animated: false)
    }
    
    private func presentPillTypeBottomSheet() {
        let pillTypeVC = PillTypeBottomSheetViewController()
        
        pillTypeVC.pillInfoSelected
            .bind(to: viewModel.input.pillInfoSelected)
            .disposed(by: disposeBag)
        
        present(pillTypeVC, animated: false)
    }
    
    // MARK: - Debug Methods
    
    private func setupDebugGesture() {
        let tripleTabGesture = UITapGestureRecognizer(target: self, action: #selector(handleDebugTap))
        tripleTabGesture.numberOfTapsRequired = 3
        view.addGestureRecognizer(tripleTabGesture)
        print("🔧 [Debug] 화면을 3번 탭하면 캐시 상태를 확인할 수 있습니다.")
    }
    
    @objc private func handleDebugTap() {
        checkCacheStatus()
    }
    
    private func logCacheStatus() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let cacheKeys = allKeys.filter { $0.hasPrefix("medication_cache_") }
        
        print("\n📦 [Cache] 캐시 상태 요약")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📦 [Cache] 총 캐시 항목: \(cacheKeys.count)개")
        
        for cacheKey in cacheKeys.sorted() {
            let keyword = cacheKey.replacingOccurrences(of: "medication_cache_", with: "")
            let timestampKey = "medication_timestamp_" + keyword
            
            if let data = defaults.data(forKey: cacheKey),
               let medications = try? JSONDecoder().decode([MedicationInfo].self, from: data) {
                
                var status = "✅ '\(keyword)': \(medications.count)개 약물"
                
                if let timestamp = defaults.object(forKey: timestampKey) as? Date {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM-dd HH:mm:ss"
                    status += " (저장: \(formatter.string(from: timestamp)))"
                }
                
                print(status)
                
                for (index, med) in medications.prefix(3).enumerated() {
                    print("   \(index + 1). \(med.name) - \(med.manufacturer)")
                }
                if medications.count > 3 {
                    print("   ... 외 \(medications.count - 3)개")
                }
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    private func checkCacheStatus() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let cacheKeys = allKeys.filter { $0.hasPrefix("medication_cache_") }
        
        var message = "📦 캐시 상태\n\n"
        message += "총 \(cacheKeys.count)개 키워드 캐시됨\n\n"
        
        let prefetchedKeywords = prefetchKeywords.filter { keyword in
            let cacheKey = "medication_cache_" + keyword
            return cacheKeys.contains(cacheKey)
        }
        
        let missingKeywords = prefetchKeywords.filter { keyword in
            let cacheKey = "medication_cache_" + keyword
            return !cacheKeys.contains(cacheKey)
        }
        
        message += "✅ 캐시됨 (\(prefetchedKeywords.count)/\(prefetchKeywords.count)):\n"
        if !prefetchedKeywords.isEmpty {
            message += prefetchedKeywords.joined(separator: ", ") + "\n\n"
        } else {
            message += "없음\n\n"
        }
        
        if !missingKeywords.isEmpty {
            message += "❌ 미캐시됨 (\(missingKeywords.count)):\n"
            message += missingKeywords.joined(separator: ", ") + "\n\n"
        }
        
        for cacheKey in cacheKeys.sorted().prefix(5) {
            let keyword = cacheKey.replacingOccurrences(of: "medication_cache_", with: "")
            if let data = defaults.data(forKey: cacheKey),
               let medications = try? JSONDecoder().decode([MedicationInfo].self, from: data) {
                message += "• \(keyword): \(medications.count)개\n"
            }
        }
        
        let alert = UIAlertController(title: "캐시 상태 확인", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        alert.addAction(UIAlertAction(title: "캐시 초기화", style: .destructive) { _ in
            self.clearCache()
        })
        present(alert, animated: true)
        
        print("\n🔍 [Debug] 사용자가 캐시 상태를 확인했습니다.")
        logCacheStatus()
    }
    
    private func clearCache() {
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let cacheKeys = allKeys.filter { $0.hasPrefix("medication_cache_") || $0.hasPrefix("medication_timestamp_") }
        
        for key in cacheKeys {
            defaults.removeObject(forKey: key)
        }
        
        print("🗑️ [Cache] 모든 캐시 삭제 완료")
        
        let alert = UIAlertController(title: "캐시 초기화 완료", message: "모든 약물 캐시가 삭제되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}


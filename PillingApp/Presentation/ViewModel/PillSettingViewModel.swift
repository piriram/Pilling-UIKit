import UIKit
import RxSwift
import RxCocoa

// MARK: - PillSettingViewModel

final class PillSettingViewModel {
    
    struct Input {
        let pillTypeButtonTapped: AnyObserver<Void>
        let startDateButtonTapped: AnyObserver<Void>
        let dateSelected: AnyObserver<Date>
        let pillInfoSelected: AnyObserver<PillInfo>
        let nextButtonTapped: AnyObserver<Void>
    }
    
    struct Output {
        let selectedPillTypeText: Driver<String?>
        let selectedStartDateText: Driver<String?>
        let isNextButtonEnabled: Driver<Bool>
        let presentDatePicker: Signal<Void>
        let presentPillTypePicker: Signal<Void>
        let proceed: Signal<Void>
        let alertMessage: Signal<String>
        let dosageMismatchAlert: Signal<(current: (Int, Int), api: (Int, Int), itemSeq: String)>
    }
    
    // MARK: - Properties

    let input: Input
    let output: Output

    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let detailAPIService: MedicationDetailAPIServiceProtocol

    private let pillTypeButtonTappedSubject = PublishSubject<Void>()
    private let startDateButtonTappedSubject = PublishSubject<Void>()
    private let dateSelectedSubject = PublishSubject<Date>()
    private let pillInfoSelectedSubject = PublishSubject<PillInfo>()
    private let nextButtonTappedSubject = PublishSubject<Void>()
    private let alertMessageSubject = PublishSubject<String>()
    private let dosageMismatchAlertSubject = PublishSubject<(current: (Int, Int), api: (Int, Int), itemSeq: String)>()

    private let selectedPillInfoRelay = BehaviorRelay<PillInfo?>(value: nil)
    private let selectedStartDateRelay = BehaviorRelay<Date?>(value: nil)

    private let disposeBag = DisposeBag()

    // MARK: - Initialization

    init(userDefaultsManager: UserDefaultsManagerProtocol, detailAPIService: MedicationDetailAPIServiceProtocol) {
        self.userDefaultsManager = userDefaultsManager
        self.detailAPIService = detailAPIService
        
        // Input 초기화
        self.input = Input(
            pillTypeButtonTapped: pillTypeButtonTappedSubject.asObserver(),
            startDateButtonTapped: startDateButtonTappedSubject.asObserver(),
            dateSelected: dateSelectedSubject.asObserver(),
            pillInfoSelected: pillInfoSelectedSubject.asObserver(),
            nextButtonTapped: nextButtonTappedSubject.asObserver()
        )
        
        // Output에 필요한 Observable 생성
        let isNextButtonEnabled = Observable
            .combineLatest(
                selectedPillInfoRelay.asObservable(),
                selectedStartDateRelay.asObservable()
            )
            .map { pillInfo, startDate in
                guard let info = pillInfo, let _ = startDate else { return false }
                return (info.takingDays + info.breakDays) <= 28
            }
        
        let selectedPillTypeText = selectedPillInfoRelay
            .map { pillInfo -> String? in
                guard let info = pillInfo else { return nil }
                let infoText = AppStrings.PillSetting.takingBreakFormat(taking: info.takingDays, breaking: info.breakDays)
                return "\(info.name) (\(infoText))"
            }
        
        let selectedStartDateText = selectedStartDateRelay
            .map { date -> String? in
                guard let date = date else { return nil }
                return PillSettingViewModel.formatDateWithDayInfo(date: date)
            }
        
        // userDefaultsManager, detailAPIService를 캡처하여 사용
        let proceed = nextButtonTappedSubject
            .withLatestFrom(
                Observable.combineLatest(
                    selectedPillInfoRelay.asObservable(),
                    selectedStartDateRelay.asObservable()
                )
            )
            .compactMap { pillInfo, startDate -> (PillInfo, Date)? in
                guard let pillInfo = pillInfo, let startDate = startDate else {
                    return nil
                }
                return (pillInfo, startDate)
            }
            .filter { pillInfo, _ in (pillInfo.takingDays + pillInfo.breakDays) <= 28 }
            .do(onNext: { [userDefaultsManager, detailAPIService, dosageMismatchAlertSubject, disposeBag] pillInfo, startDate in
                // 기본 정보 저장
                userDefaultsManager.savePillInfo(pillInfo)
                userDefaultsManager.savePillStartDate(startDate)

                // itemSeq가 있으면 백그라운드에서 상세 API 호출
                if let itemSeq = pillInfo.itemSeq {
                    detailAPIService.fetchMedicationDetail(itemSeq: itemSeq)
                        .observe(on: MainScheduler.instance)
                        .subscribe(
                            onNext: { detailInfo in
                                guard let detail = detailInfo else { return }

                                // 상세 정보 저장
                                let storedInfo = detail.toStoredInfo()
                                userDefaultsManager.saveMedicationDetail(storedInfo, forItemSeq: itemSeq)
                                print("✅ 상세 정보 저장 완료: \(detail.itemName)")

                                // 복용 주기 비교
                                let apiDosage = detail.parsedDosage()
                                let currentDosage = (pillInfo.takingDays, pillInfo.breakDays)

                                print("⚖️ [복용 주기 비교] \(pillInfo.name)")
                                print("   현재 선택: \(currentDosage.0)일 복용 / \(currentDosage.1)일 휴약")
                                print("   API 결과: \(apiDosage.0)일 복용 / \(apiDosage.1)일 휴약")

                                if apiDosage != currentDosage {
                                    print("   ⚠️ 불일치 감지 → Alert 표시")
                                    dosageMismatchAlertSubject.onNext((
                                        current: currentDosage,
                                        api: apiDosage,
                                        itemSeq: itemSeq
                                    ))
                                } else {
                                    print("   ✅ 일치")
                                }
                            },
                            onError: { error in
                                print("⚠️ 상세 정보 조회 실패: \(error.localizedDescription)")
                            }
                        )
                        .disposed(by: disposeBag)
                }
            })
            .map { _ in () }
            .asSignal(onErrorSignalWith: .empty())
        
        // Output 초기화
        self.output = Output(
            selectedPillTypeText: selectedPillTypeText.asDriver(onErrorJustReturn: nil),
            selectedStartDateText: selectedStartDateText.asDriver(onErrorJustReturn: nil),
            isNextButtonEnabled: isNextButtonEnabled.asDriver(onErrorJustReturn: false),
            presentDatePicker: startDateButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            presentPillTypePicker: pillTypeButtonTappedSubject.asSignal(onErrorSignalWith: .empty()),
            proceed: proceed,
            alertMessage: alertMessageSubject.asSignal(onErrorSignalWith: .empty()),
            dosageMismatchAlert: dosageMismatchAlertSubject.asSignal(onErrorSignalWith: .empty())
        )
        
        // 바인딩
        bindActions()
    }
    
    // MARK: - Bind
    
    private func bindActions() {
        pillInfoSelectedSubject
            .subscribe(onNext: { [weak self] pillInfo in
                let total = pillInfo.takingDays + pillInfo.breakDays
                if total <= 28 {
                    self?.selectedPillInfoRelay.accept(pillInfo)
                } else {
                    self?.alertMessageSubject.onNext(AppStrings.PillSetting.warningLabel)
                }
            })
            .disposed(by: disposeBag)
        
        dateSelectedSubject
            .subscribe(onNext: { [weak self] date in
                self?.selectedStartDateRelay.accept(date)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Methods
    
    private static func calculateDaysSinceStart(from startDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: Date())
        return (components.day ?? 0) + 1 // 1일차부터 시작
    }
    
    private static func formatDateWithDayInfo(date: Date) -> String {
        let dateText = date.formatted(style: .monthDay)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: date)
        if selectedDay < today {
            let days = calculateDaysSinceStart(from: date)
            return "\(dateText) (\(AppStrings.PillSetting.dayOrdinal(days)))"
        } else if selectedDay == today {
            return "\(dateText) (\(AppStrings.PillSetting.today))"
        } else {
            let components = calendar.dateComponents([.day], from: today, to: selectedDay)
            let daysRemaining = components.day ?? 0
            return "\(dateText) (\(AppStrings.PillSetting.daysRemaining(daysRemaining)))"
        }
    }
}

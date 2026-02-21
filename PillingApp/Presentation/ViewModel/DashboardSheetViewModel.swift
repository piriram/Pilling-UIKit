import Foundation
import RxSwift
import RxCocoa

protocol DashboardSheetViewModel {
    func transform(_ input: DashboardSheetViewModelInput) -> DashboardSheetViewModelOutput
}

struct DashboardSheetViewModelInput {
    let viewDidAppear: Observable<Void>
    let tapNotTaken: Observable<Void>
    let tapTaken: Observable<Void>
    let tapTakenDouble: Observable<Void>
    let memoText: Observable<String>
    let requestDismiss: Observable<Void>
    let timeChanged: Observable<Date>
}

struct DashboardSheetViewModelOutput {
    let shouldShowSheet: Signal<Void>
    let initialButtonTag: Driver<StatusButtonTag>
    let formattedTime: Driver<String>
    let dismiss: Signal<(PillStatus?, String)>
}

final class DefaultDashboardSheetViewModel: DashboardSheetViewModel {
    
    private let selectedDate: Date
    private let initialMemo: String
    private let initialStatus: PillStatus?
    private let disposeBag = DisposeBag()
    
    private var selectedStatus: PillStatus?
    private var currentTakenAt: Date?
    private var currentMemo: String
    
    init(
        selectedDate: Date,
        initialMemo: String,
        initialStatus: PillStatus?,
        takenAt: Date? = nil
    ) {
        self.selectedDate = selectedDate
        self.initialMemo = initialMemo
        self.initialStatus = initialStatus
        self.selectedStatus = initialStatus
        self.currentTakenAt = takenAt
        self.currentMemo = initialMemo
    }
    
    func transform(_ input: DashboardSheetViewModelInput) -> DashboardSheetViewModelOutput {
        
        // Update takenAt when timeChanged emits
        input.timeChanged
            .subscribe(onNext: { [weak self] date in
                self?.currentTakenAt = date
            })
            .disposed(by: disposeBag)
        
        // Update memo when it changes
        input.memoText
            .subscribe(onNext: { [weak self] text in
                self?.currentMemo = text
            })
            .disposed(by: disposeBag)
        
        // 상태 업데이트
        input.tapNotTaken
            .subscribe(onNext: { [weak self] in
                self?.selectedStatus = .notTaken
            })
            .disposed(by: disposeBag)

        input.tapTaken
            .subscribe(onNext: { [weak self] in
                self?.selectedStatus = .taken
            })
            .disposed(by: disposeBag)

        input.tapTakenDouble
            .subscribe(onNext: { [weak self] in
                print("🔍 [SheetViewModel] tapTakenDouble - 2알 복용 상태로 변경")
                self?.selectedStatus = .takenDouble
                print("🔍 [SheetViewModel] selectedStatus = \(String(describing: self?.selectedStatus))")
            })
            .disposed(by: disposeBag)
        
        let shouldShowSheet = input.viewDidAppear
            .asSignal(onErrorSignalWith: .empty())
        
        let initialButtonTag = Driver.just(initialStatus)
            .map { status -> StatusButtonTag in
                guard let status = status else { return .none }
                return PillStatusMapper.mapStatusToButtonTag(status)
            }
        
        let formattedTime = Driver.just(currentTakenAt)
            .map { [weak self] date -> String in
                self?.formatTime(date) ?? "-"
            }
        
        let updatedTime = input.timeChanged
            .map { [weak self] date -> String in
                self?.formatTime(date) ?? "-"
            }
            .asDriver(onErrorJustReturn: "-")
        
        let finalFormattedTime = Driver.merge(formattedTime, updatedTime)
        
        let statusTapped = Observable.merge(
            input.tapNotTaken,
            input.tapTaken,
            input.tapTakenDouble
        )
        
        let dismissTrigger = Observable.merge(
            input.requestDismiss,
            statusTapped
        )
        
        let dismiss = dismissTrigger
            .map { [weak self] _ -> (PillStatus?, String) in
                guard let self = self else { return (nil, "") }
                print("🔍 [SheetViewModel] dismiss - selectedStatus: \(String(describing: self.selectedStatus)), memo: \(self.currentMemo)")
                return (self.selectedStatus, self.currentMemo)
            }
            .asSignal(onErrorSignalWith: .empty())
        
        return DashboardSheetViewModelOutput(
            shouldShowSheet: shouldShowSheet,
            initialButtonTag: initialButtonTag,
            formattedTime: finalFormattedTime,
            dismiss: dismiss
        )
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        return date.formatted(style: .time24Hour)
    }
}

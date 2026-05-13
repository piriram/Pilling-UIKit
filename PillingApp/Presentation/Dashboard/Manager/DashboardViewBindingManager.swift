import UIKit
import RxSwift
import RxCocoa

final class DashboardViewBindingManager {
    
    // MARK: - Properties
    
    private let viewModel: DashboardViewModel
    private let stasticsViewModel: StatisticsViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(
        viewModel: DashboardViewModel,
        stasticsViewModel: StatisticsViewModel
    ) {
        self.viewModel = viewModel
        self.stasticsViewModel = stasticsViewModel
    }
    
    // MARK: - Public Methods
    
    func bindAll(
        infoView: DashboardMiddleView,
        bottomView: DashboardBottomView,
        topButtonsView: DashboardTopButtonsView,
        stasticsView: StatisticsContentView,
        coordinator: DashboardCoordinator,
        sheetPresenter: DashboardSheetPresenter,
        onBackgroundUpdate: @escaping () -> Void,
        onRetryAlert: @escaping (@escaping () -> Void) -> Void,
        onNewCycleAlert: @escaping () -> Void,
        onCompletionFloatingView: @escaping () -> Void,
        onStatusUpdateError: @escaping () -> Void = {}
    ) {
        bindViewModel(
            infoView: infoView,
            bottomView: bottomView,
            sheetPresenter: sheetPresenter,
            onBackgroundUpdate: onBackgroundUpdate
        )

        bindStasticsViewModel(
            stasticsView: stasticsView,
            bottomView: bottomView,
            sheetPresenter: sheetPresenter
        )

        bindTopButtons(
            topButtonsView: topButtonsView,
            coordinator: coordinator,
            sheetPresenter: sheetPresenter
        )

        bindBottomView(bottomView: bottomView)

        bindAlert(
            onRetryAlert: onRetryAlert,
            onNewCycleAlert: onNewCycleAlert,
            onCompletionFloatingView: onCompletionFloatingView,
            onStatusUpdateError: onStatusUpdateError
        )
    }
    
    // MARK: - Private Binding Methods
    
    private func bindViewModel(
        infoView: DashboardMiddleView,
        bottomView: DashboardBottomView,
        sheetPresenter: DashboardSheetPresenter,
        onBackgroundUpdate: @escaping () -> Void
    ) {
        // Calendar items
        viewModel.items
            .asObservable()
            .scan((previous: [DayItem](), current: [DayItem]())) { state, newItems in
                (previous: state.current, current: newItems)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }

                let previousItems = state.previous
                let currentItems = state.current

                if let updatedItem = self.findSingleStatusChangedItem(
                    previous: previousItems,
                    current: currentItems
                ) {
                    infoView.updateCalendarItem(for: updatedItem)
                    return
                }

                infoView.applyCalendarSnapshot(with: currentItems)
            })
            .disposed(by: disposeBag)
        
        // Pill info
        viewModel.pillInfo
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: PillInfo(name: "", takingDays: 0, breakDays: 0))
            .drive(onNext: { pillInfo in
                infoView.configure(with: pillInfo)
            })
            .disposed(by: disposeBag)

        // User settings (for scheduled time display)
        viewModel.settings
            .asDriver()
            .drive(onNext: { settings in
                infoView.configure(with: settings)
            })
            .disposed(by: disposeBag)

        // Current cycle
        viewModel.currentCycle
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: Cycle(
                id: UUID(),
                cycleNumber: 1,
                startDate: Date(),
                activeDays: 21,
                breakDays: 7,
                scheduledTime: "09:00",
                records: [],
                createdAt: Date()
            ))
            .drive(onNext: { cycle in
                infoView.configure(with: cycle)
                infoView.updateCalendarWeekdayStart(from: cycle.startDate)
                onBackgroundUpdate()
            })
            .disposed(by: disposeBag)
        
        // Dashboard message
        viewModel.dashboardMessage
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: DashboardMessage(text: "", imageName: .rest, icon: .rest, backgroundImageName: "background_rest"))
            .drive(onNext: { message in
                infoView.configure(with: message)
                onBackgroundUpdate()
            })
            .disposed(by: disposeBag)
        
        // Can take pill
        Observable.combineLatest(
            viewModel.canTakePill.asObservable(),
            viewModel.currentCycle.asObservable()
        )
        .asDriver(onErrorJustReturn: (false, nil))
        .drive(onNext: { canTake, cycle in
            bottomView.updateButton(canTake: canTake, cycle: cycle)
        })
        .disposed(by: disposeBag)
        
        // Calendar cell selection
        infoView.onCalendarCellSelected = { [weak self] index, item in
            guard let self = self,
                  let cycle = self.viewModel.currentCycle.value else { return }
            
            sheetPresenter.presentCalendarSheet(
                for: index,
                item: item,
                cycle: cycle,
                onStatusUpdate: { [weak self] index, status, memo, takenAt in
                    print("🔍 [ViewBindingManager] onStatusUpdate - index: \(index), status: \(status), memo: \(memo ?? "nil"), takenAt: \(String(describing: takenAt))")
                    self?.viewModel.updateState(
                        at: index,
                        to: status,
                        memo: memo,
                        takenAt: takenAt
                    )
                }
            )
        }
    }
    
    private func bindStasticsViewModel(
        stasticsView: StatisticsContentView,
        bottomView: DashboardBottomView,
        sheetPresenter: DashboardSheetPresenter
    ) {
        let viewDidLoadSubject = PublishSubject<Void>()
        let leftArrowTappedSubject = PublishSubject<Void>()
        let rightArrowTappedSubject = PublishSubject<Void>()
        let periodButtonTappedSubject = PublishSubject<Void>()
        let dataChangedSubject = PublishSubject<Void>()

        // DashboardViewModel의 currentCycle 변경 감지하여 통계 새로고침
        viewModel.currentCycle
            .skip(1)  // 초기값 무시
            .map { _ in () }
            .bind(to: dataChangedSubject)
            .disposed(by: disposeBag)

        let input = StatisticsViewModel.Input(
            viewDidLoad: viewDidLoadSubject.asObservable(),
            leftArrowTapped: leftArrowTappedSubject.asObservable(),
            rightArrowTapped: rightArrowTappedSubject.asObservable(),
            periodButtonTapped: periodButtonTappedSubject.asObservable(),
            dataChanged: dataChangedSubject.asObservable()
        )

        let output = stasticsViewModel.transform(input: input)
        
        output.currentPeriodData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { data in
                stasticsView.configure(with: data)
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(output.isLeftArrowEnabled, output.isRightArrowEnabled)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { isLeftEnabled, isRightEnabled in
                stasticsView.updateArrowButtons(
                    isLeftEnabled: isLeftEnabled,
                    isRightEnabled: isRightEnabled
                )
            })
            .disposed(by: disposeBag)
        
        output.periodList
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] periodList in
                guard let self = self else { return }
                sheetPresenter.showPeriodSelectionAlert(
                    periodList: periodList,
                    currentIndex: self.stasticsViewModel.getCurrentIndex(),
                    onPeriodSelected: { [weak self] index in
                        self?.stasticsViewModel.selectPeriod(at: index)
                    }
                )
            })
            .disposed(by: disposeBag)

        stasticsView.leftArrowTapped = {
            leftArrowTappedSubject.onNext(())
        }

        stasticsView.rightArrowTapped = {
            rightArrowTappedSubject.onNext(())
        }

        stasticsView.periodButtonTapped = {
            periodButtonTappedSubject.onNext(())
        }

        // 즉시 데이터 로드 trigger (DashboardViewController 로드 시점에)
        viewDidLoadSubject.onNext(())
    }
    
    private func bindTopButtons(
        topButtonsView: DashboardTopButtonsView,
        coordinator: DashboardCoordinator,
        sheetPresenter: DashboardSheetPresenter
    ) {
        topButtonsView.historyButtonTapped
            .subscribe(onNext: {
                coordinator.navigateToCycleHistory()
            })
            .disposed(by: disposeBag)
        
        topButtonsView.infoButtonTapped
            .subscribe(onNext: {
                sheetPresenter.presentInfoFloatingView()
            })
            .disposed(by: disposeBag)
        
        topButtonsView.gearButtonTapped
            .subscribe(onNext: {
                coordinator.navigateToSettings()
            })
            .disposed(by: disposeBag)
    }
    
    private func bindBottomView(bottomView: DashboardBottomView) {
        bottomView.takePillButton.rx.tap
            .subscribe(onNext: { [weak self] in
                if bottomView.isRestPeriod {
                    bottomView.showRestPeriodTooltip()
                } else {
                    self?.viewModel.takePill()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindAlert(
        onRetryAlert: @escaping (@escaping () -> Void) -> Void,
        onNewCycleAlert: @escaping () -> Void,
        onCompletionFloatingView: @escaping () -> Void,
        onStatusUpdateError: @escaping () -> Void
    ) {
        viewModel.showRetryAlert
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                onRetryAlert { [weak self] in
                    self?.viewModel.reloadData()
                }
            })
            .disposed(by: disposeBag)

        viewModel.showNewCycleAlert
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {
                onNewCycleAlert()
            })
            .disposed(by: disposeBag)

        viewModel.showCompletionFloatingView
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {
                onCompletionFloatingView()
            })
            .disposed(by: disposeBag)

        viewModel.showStatusUpdateError
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: {
                onStatusUpdateError()
            })
            .disposed(by: disposeBag)
    }

    private func findSingleStatusChangedItem(
        previous: [DayItem],
        current: [DayItem]
    ) -> DayItem? {
        guard
            !previous.isEmpty,
            previous.count == current.count
        else {
            return nil
        }

        let calendar = Calendar.current
        var changedItems: [DayItem] = []

        for (oldItem, newItem) in zip(previous, current) {
            let isSameDay = calendar.isDate(oldItem.date, inSameDayAs: newItem.date)
            let sameStructure = isSameDay &&
                oldItem.cycleDay == newItem.cycleDay &&
                oldItem.scheduledDateTime == newItem.scheduledDateTime

            guard sameStructure else {
                return nil
            }

            if oldItem.status == newItem.status {
                continue
            }

            changedItems.append(
                DayItem(
                    id: oldItem.id,
                    cycleDay: newItem.cycleDay,
                    date: newItem.date,
                    status: newItem.status,
                    scheduledDateTime: newItem.scheduledDateTime
                )
            )

            if changedItems.count > 1 {
                return nil
            }
        }

        return changedItems.count == 1 ? changedItems[0] : nil
    }
}

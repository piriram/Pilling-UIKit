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
        onCompletionFloatingView: @escaping () -> Void
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
            onCompletionFloatingView: onCompletionFloatingView
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
            .asDriver()
            .drive(onNext: { items in
                infoView.applyCalendarSnapshot(with: items)
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
        onCompletionFloatingView: @escaping () -> Void
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
    }
}

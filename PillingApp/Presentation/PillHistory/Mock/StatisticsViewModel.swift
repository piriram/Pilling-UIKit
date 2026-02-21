import RxSwift
import RxCocoa

// MARK: - ViewModel
final class StatisticsViewModel {

    struct Input {
        let viewDidLoad: Observable<Void>
        let leftArrowTapped: Observable<Void>
        let rightArrowTapped: Observable<Void>
        let periodButtonTapped: Observable<Void>
        let dataChanged: Observable<Void>  // 데이터 변경 알림
    }

    struct Output {
        let currentPeriodData: Observable<PeriodRecordDTO>
        let isLeftArrowEnabled: Observable<Bool>
        let isRightArrowEnabled: Observable<Bool>
        let periodList: Observable<[PeriodRecordDTO]>
        let pageControlState: Observable<(currentIndex: Int, totalCount: Int)>  // 페이지 컨트롤용
    }

    private let fetchStatisticsDataUseCase: FetchStatisticsDataUseCaseProtocol
    private let analytics: AnalyticsServiceProtocol
    private let disposeBag = DisposeBag()
    private let currentIndexSubject = BehaviorSubject<Int>(value: 0)
    private let dataListSubject = BehaviorSubject<[PeriodRecordDTO]>(value: [])

    init(
        fetchStatisticsDataUseCase: FetchStatisticsDataUseCaseProtocol,
        analytics: AnalyticsServiceProtocol = DIContainer.shared.getAnalyticsService()
    ) {
        self.fetchStatisticsDataUseCase = fetchStatisticsDataUseCase
        self.analytics = analytics
    }
    
    func transform(input: Input) -> Output {
        // Load statistics data on viewDidLoad or when data changes
        Observable.merge(
            input.viewDidLoad,
            input.dataChanged
        )
        .flatMapLatest { [weak self] _ -> Observable<[PeriodRecordDTO]> in
            guard let self = self else { return .just([]) }
            return self.fetchStatisticsDataUseCase.execute()
                .catch { error in
                    print("❌ Failed to fetch statistics data: \(error)")
                    return .just([])
                }
        }
        .bind(to: dataListSubject)
        .disposed(by: disposeBag)

        input.leftArrowTapped
            .do(onNext: { [weak self] _ in
                self?.analytics.logEvent(.statisticsPeriodChanged(direction: "left"))
            })
            .withLatestFrom(currentIndexSubject)
            .filter { $0 > 0 }
            .map { $0 - 1 }
            .bind(to: currentIndexSubject)
            .disposed(by: disposeBag)

        input.rightArrowTapped
            .do(onNext: { [weak self] _ in
                self?.analytics.logEvent(.statisticsPeriodChanged(direction: "right"))
            })
            .withLatestFrom(Observable.combineLatest(currentIndexSubject, dataListSubject))
            .filter { index, dataList in
                return index < dataList.count - 1
            }
            .map { index, _ in index + 1 }
            .bind(to: currentIndexSubject)
            .disposed(by: disposeBag)

        let currentPeriodData = Observable.combineLatest(currentIndexSubject, dataListSubject)
            .map { index, dataList -> PeriodRecordDTO in
                guard !dataList.isEmpty, index < dataList.count else {
                    return PeriodRecordDTO(
                        startDate: "",
                        endDate: "",
                        startDateShort: "",
                        endDateShort: "",
                        completionRate: 0,
                        medicineName: "",
                        records: [],
                        skippedCount: 0,
                        sideEffectStats: [],
                        isEmpty: true
                    )
                }
                return dataList[index]
            }

        let isLeftArrowEnabled = currentIndexSubject
            .map { $0 > 0 }

        let isRightArrowEnabled = Observable.combineLatest(currentIndexSubject, dataListSubject)
            .map { index, dataList in
                return index < dataList.count - 1
            }

        let periodList = input.periodButtonTapped
            .withLatestFrom(dataListSubject)

        // 페이지 컨트롤 상태 (현재 인덱스, 전체 개수)
        let pageControlState = Observable.combineLatest(currentIndexSubject, dataListSubject)
            .map { (currentIndex: $0, totalCount: $1.count) }

        return Output(
            currentPeriodData: currentPeriodData,
            isLeftArrowEnabled: isLeftArrowEnabled,
            isRightArrowEnabled: isRightArrowEnabled,
            periodList: periodList,
            pageControlState: pageControlState
        )
    }

    func selectPeriod(at index: Int) {
        analytics.logEvent(.statisticsPeriodSelected(index: index))
        currentIndexSubject.onNext(index)
    }

    func getCurrentIndex() -> Int {
        return (try? currentIndexSubject.value()) ?? 0
    }
}

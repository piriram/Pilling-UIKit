import UIKit

final class DashboardSheetPresenter {
    
    // MARK: - Properties

    private weak var viewController: UIViewController?
    private let userDefaultsManager: UserDefaultsManagerProtocol
    private let timeProvider: TimeProvider

    // MARK: - Initialization

    init(
        viewController: UIViewController,
        userDefaultsManager: UserDefaultsManagerProtocol,
        timeProvider: TimeProvider
    ) {
        self.viewController = viewController
        self.userDefaultsManager = userDefaultsManager
        self.timeProvider = timeProvider
    }
    
    // MARK: - Calendar Sheet Presentation
    
    func presentCalendarSheet(
        for index: Int,
        item: DayItem,
        cycle: Cycle,
        onStatusUpdate: @escaping (Int, PillStatus, String?, Date?) -> Void
    ) {
        guard let viewController = viewController else { return }
        
        // Calculate day text (e.g., "3일차/28")
        let calendar = Calendar.current
        let daysSinceStart = max(0, calendar.dateComponents([.day], from: cycle.startDate, to: item.date).day ?? 0)
        let currentDay = min(daysSinceStart + 1, cycle.totalDays)
        let dayText = AppStrings.Dashboard.dayProgressFormat(current: currentDay, total: cycle.totalDays)
        
        // Safely access existing memo/taken time
        let existingMemo: String = {
            guard cycle.records.indices.contains(index) else { return "" }
            return cycle.records[index].memo ?? ""
        }()
        
        var currentTakenAt: Date? = {
            guard cycle.records.indices.contains(index) else { return nil }
            return cycle.records[index].takenAt
        }()
        
        // Create sheet VC
        let sheetVC = DashboardSheetViewController(
            selectedDate: item.date,
            initialMemo: existingMemo,
            takenAt: currentTakenAt,
            initialStatus: item.status,
            userDefaultsManager: userDefaultsManager,
            timeProvider: timeProvider,
            onDataChanged: { [weak self] chosenStatus, memo in
                guard let self = self else { return }
                print("🔍 [SheetPresenter] onDataChanged - chosenStatus: \(String(describing: chosenStatus)), memo: \(memo)")
                // If status not chosen, maintain existing status
                let finalStatus = chosenStatus ?? item.status
                print("🔍 [SheetPresenter] finalStatus: \(finalStatus)")

                // 복용 상태일 때만 takenAt 전달, 미복용 상태면 nil
                let finalTakenAt = finalStatus.isTaken ? currentTakenAt : nil

                print("🔍 [SheetPresenter] Calling onStatusUpdate with index: \(index), status: \(finalStatus)")
                onStatusUpdate(index, finalStatus, memo, finalTakenAt)
            },
            onTimeChanged: { [weak self] newTime in
                guard let self = self else { return }
                // Time change is reflected immediately
                currentTakenAt = newTime
                onStatusUpdate(index, item.status, existingMemo, newTime)
            }
        )
        
        sheetVC.titleText = dayText
        sheetVC.title = ""
        
        // Initial selection is now handled automatically by ViewModel
        
        // Wrap in navigation controller
        let nav = UINavigationController(rootViewController: sheetVC)
        nav.modalPresentationStyle = .overFullScreen
        nav.modalTransitionStyle = .crossDissolve
        nav.navigationBar.isHidden = true
        
        viewController.present(nav, animated: false)
    }
    
    // MARK: - Info Floating View Presentation
    
    func presentInfoFloatingView() {
        guard let viewController = viewController else {
            return
        }
        
        let infoView = DashboardGuideView()
        infoView.onConfirm = { [weak infoView] in
            infoView?.dismiss()
        }
        infoView.show(in: viewController.view)
    }
    
    // MARK: - Period Selection Alert
    
    func showPeriodSelectionAlert(
        periodList: [PeriodRecordDTO],
        currentIndex: Int,
        onPeriodSelected: @escaping (Int) -> Void
    ) {
        guard let viewController = viewController else { return }
        
        let alert = UIAlertController(title: AppStrings.Statistics.periodSelectionTitle, message: nil, preferredStyle: .actionSheet)
        
        for (index, data) in periodList.enumerated() {
            let action = UIAlertAction(title: "\(data.startDate) - \(data.endDate)", style: .default) { _ in
                onPeriodSelected(index)
            }
            if index == currentIndex {
                action.setValue(true, forKey: "checked")
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: AppStrings.Common.cancelTitle, style: .cancel))
        
        viewController.present(alert, animated: true)
    }
}

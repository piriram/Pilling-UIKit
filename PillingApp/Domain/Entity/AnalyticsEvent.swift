import Foundation

enum AnalyticsEvent {
    // 약 복용 관련
    case pillTaken(date: Date, status: PillStatus)
    case pillStatusChanged(from: PillStatus, to: PillStatus)
    case pillButtonTapped
    case calendarCellTapped(cycleDay: Int)
    case timeChanged(newTime: String)

    // 사이클 관련
    case cycleCreated(duration: Int, startDate: Date)
    case cycleCompleted(totalDays: Int)
    case cycleCompletionFloatingShown
    case newCycleStarted

    // 부작용 관련
    case sideEffectAdded(tag: String, date: Date)
    case sideEffectRemoved(tag: String)
    case sideEffectTagSelected(tags: [String], count: Int)
    case sideEffectTagCreated(tagName: String)
    case sideEffectTagDeleted(tagName: String)
    case sideEffectVisibilityToggled(tagName: String, isVisible: Bool)
    case sideEffectReordered

    // 화면 진입
    case screenViewed(screenName: String)
    case dashboardSwipeToStatistics
    case statisticsSwipeToDashboard

    // 설정 변경
    case settingsChanged(type: String, value: String)
    case notificationToggled(isEnabled: Bool)
    case notificationMessageChanged
    case pillInfoEditStarted

    // 온보딩
    case onboardingStarted
    case onboardingStepCompleted(step: Int)
    case onboardingCompleted
    case pillInfoEntered(takingDays: Int, breakDays: Int)
    case scheduleTimeSet(time: String)
    case notificationPermissionRequested
    case notificationPermissionGranted(granted: Bool)

    // 통계
    case statisticsPeriodChanged(direction: String)
    case statisticsPeriodSelected(index: Int)

    // 가이드 & 정보
    case infoButtonTapped
    case guideViewShown

    // 앱 라이프사이클
    case appLaunched
    case appForegrounded
    case appBackgrounded
    case dailyFirstAccess

    // 에러
    case dataLoadFailed(errorType: String)
    case retryButtonTapped

    // 약 검색 & 선택
    case medicationSearched(keyword: String)
    case medicationSelected(id: String, name: String, keyword: String)
    case medicationListViewed(count: Int)

    // MARK: - 이벤트명 (Firebase 전송용)
    var name: String {
        switch self {
        // 약 복용
        case .pillTaken: return "pill_taken"
        case .pillStatusChanged: return "pill_status_changed"
        case .pillButtonTapped: return "pill_button_tapped"
        case .calendarCellTapped: return "calendar_cell_tapped"
        case .timeChanged: return "time_changed"

        // 사이클
        case .cycleCreated: return "cycle_created"
        case .cycleCompleted: return "cycle_completed"
        case .cycleCompletionFloatingShown: return "cycle_completion_floating_shown"
        case .newCycleStarted: return "new_cycle_started"

        // 부작용
        case .sideEffectAdded: return "side_effect_added"
        case .sideEffectRemoved: return "side_effect_removed"
        case .sideEffectTagSelected: return "side_effect_tag_selected"
        case .sideEffectTagCreated: return "side_effect_tag_created"
        case .sideEffectTagDeleted: return "side_effect_tag_deleted"
        case .sideEffectVisibilityToggled: return "side_effect_visibility_toggled"
        case .sideEffectReordered: return "side_effect_reordered"

        // 화면
        case .screenViewed: return "screen_viewed"
        case .dashboardSwipeToStatistics: return "dashboard_swipe_to_statistics"
        case .statisticsSwipeToDashboard: return "statistics_swipe_to_dashboard"

        // 설정
        case .settingsChanged: return "settings_changed"
        case .notificationToggled: return "notification_toggled"
        case .notificationMessageChanged: return "notification_message_changed"
        case .pillInfoEditStarted: return "pill_info_edit_started"

        // 온보딩
        case .onboardingStarted: return "onboarding_started"
        case .onboardingStepCompleted: return "onboarding_step_completed"
        case .onboardingCompleted: return "onboarding_completed"
        case .pillInfoEntered: return "pill_info_entered"
        case .scheduleTimeSet: return "schedule_time_set"
        case .notificationPermissionRequested: return "notification_permission_requested"
        case .notificationPermissionGranted: return "notification_permission_granted"

        // 통계
        case .statisticsPeriodChanged: return "statistics_period_changed"
        case .statisticsPeriodSelected: return "statistics_period_selected"

        // 가이드
        case .infoButtonTapped: return "info_button_tapped"
        case .guideViewShown: return "guide_view_shown"

        // 앱 라이프사이클
        case .appLaunched: return "app_launched"
        case .appForegrounded: return "app_foregrounded"
        case .appBackgrounded: return "app_backgrounded"
        case .dailyFirstAccess: return "daily_first_access"

        // 에러
        case .dataLoadFailed: return "data_load_failed"
        case .retryButtonTapped: return "retry_button_tapped"

        // 약 검색
        case .medicationSearched: return "medication_searched"
        case .medicationSelected: return "medication_selected"
        case .medicationListViewed: return "medication_list_viewed"
        }
    }

    // MARK: - 파라미터 (Firebase 전송용)
    var parameters: [String: Any] {
        switch self {
        // 약 복용
        case .pillTaken(let date, let status):
            return [
                "date": ISO8601DateFormatter().string(from: date),
                "status": status.rawValue
            ]

        case .pillStatusChanged(let from, let to):
            return [
                "from_status": from.rawValue,
                "to_status": to.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ]

        case .pillButtonTapped:
            return [:]

        case .calendarCellTapped(let cycleDay):
            return ["cycle_day": cycleDay]

        case .timeChanged(let newTime):
            return ["new_time": newTime]

        // 사이클
        case .cycleCreated(let duration, let startDate):
            return [
                "duration_days": duration,
                "start_date": ISO8601DateFormatter().string(from: startDate)
            ]

        case .cycleCompleted(let totalDays):
            return [
                "total_days": totalDays,
                "completion_date": ISO8601DateFormatter().string(from: Date())
            ]

        case .cycleCompletionFloatingShown:
            return [:]

        case .newCycleStarted:
            return [:]

        // 부작용
        case .sideEffectAdded(let tag, let date):
            return [
                "tag": tag,
                "date": ISO8601DateFormatter().string(from: date)
            ]

        case .sideEffectRemoved(let tag):
            return ["tag": tag]

        case .sideEffectTagSelected(let tags, let count):
            return [
                "tags": tags.joined(separator: ","),
                "count": count
            ]

        case .sideEffectTagCreated(let tagName):
            return ["tag_name": tagName]

        case .sideEffectTagDeleted(let tagName):
            return ["tag_name": tagName]

        case .sideEffectVisibilityToggled(let tagName, let isVisible):
            return [
                "tag_name": tagName,
                "is_visible": isVisible
            ]

        case .sideEffectReordered:
            return [:]

        // 화면
        case .screenViewed(let screenName):
            return ["screen_name": screenName]

        case .dashboardSwipeToStatistics:
            return [:]

        case .statisticsSwipeToDashboard:
            return [:]

        // 설정
        case .settingsChanged(let type, let value):
            return [
                "setting_type": type,
                "setting_value": value
            ]

        case .notificationToggled(let isEnabled):
            return ["is_enabled": isEnabled]

        case .notificationMessageChanged:
            return [:]

        case .pillInfoEditStarted:
            return [:]

        // 온보딩
        case .onboardingStarted:
            return [:]

        case .onboardingStepCompleted(let step):
            return ["step": step]

        case .onboardingCompleted:
            return [:]

        case .pillInfoEntered(let takingDays, let breakDays):
            return [
                "taking_days": takingDays,
                "break_days": breakDays
            ]

        case .scheduleTimeSet(let time):
            return ["time": time]

        case .notificationPermissionRequested:
            return [:]

        case .notificationPermissionGranted(let granted):
            return ["granted": granted]

        // 통계
        case .statisticsPeriodChanged(let direction):
            return ["direction": direction]

        case .statisticsPeriodSelected(let index):
            return ["index": index]

        // 가이드
        case .infoButtonTapped:
            return [:]

        case .guideViewShown:
            return [:]

        // 앱 라이프사이클
        case .appLaunched:
            return [:]

        case .appForegrounded:
            return [:]

        case .appBackgrounded:
            return [:]

        case .dailyFirstAccess:
            return [:]

        // 에러
        case .dataLoadFailed(let errorType):
            return ["error_type": errorType]

        case .retryButtonTapped:
            return [:]

        // 약 검색
        case .medicationSearched(let keyword):
            return [
                "keyword": keyword,
                "timestamp": Date().timeIntervalSince1970
            ]

        case .medicationSelected(let id, let name, let keyword):
            return [
                "medication_id": id,
                "medication_name": name,
                "search_keyword": keyword,
                "timestamp": Date().timeIntervalSince1970
            ]

        case .medicationListViewed(let count):
            return [
                "medication_count": count,
                "timestamp": Date().timeIntervalSince1970
            ]
        }
    }
}

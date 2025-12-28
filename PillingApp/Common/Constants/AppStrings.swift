import Foundation

enum AppStrings{

    enum Common{
        static let alertTitle = "common.alert_title".localized
        static let okBtnTitle = "common.ok_button".localized
        static let errorTitle = "common.error_title".localized
        static let cancelTitle = "common.cancel_title".localized
        static let confirmTitle = "common.confirm_title".localized
        static let retryTitle = "common.retry_title".localized
        static let goToSettings = "common.go_to_settings".localized
    }
    
    enum PillSetting{
        static let mainTitle = "pill_setting.main_title".localized
        static let subtitle = "pill_setting.subtitle".localized
        static let btnTitle = "pill_setting.button_title".localized
        static let ctnBtnTitle = "pill_setting.start_date_button".localized
        static let nextBtnTitle = "pill_setting.next_button".localized
        static let navTitle = "pill_setting.nav_title".localized
        static let nameTitle = "pill_setting.name_title".localized
        static let takingDays = "pill_setting.taking_days".localized
        static let takingBtn = "pill_setting.taking_button".localized
        static let breakLabel = "pill_setting.break_label".localized
        static let breakDay = "pill_setting.break_day".localized
        static let warningLabel = "pill_setting.warning_label".localized
        static let settingComplete = "pill_setting.setting_complete".localized
        static let titleLabel = "pill_setting.title_label".localized
        static func daysFormat(_ days: Int) -> String {
            "pill_setting.days_format".localized(with: days)
        }
        static func takingBreakFormat(taking: Int, breaking: Int) -> String {
            "pill_setting.taking_break_format".localized(with: taking, breaking)
        }
        static func dayOrdinal(_ day: Int) -> String {
            "pill_setting.day_ordinal".localized(with: day)
        }
        static let today = "pill_setting.today".localized
        static func daysRemaining(_ days: Int) -> String {
            "pill_setting.days_remaining".localized(with: days)
        }
    }
    enum SettingFloating{
        static let titleLabel = "setting_floating.title".localized
        static let subTitleLabel = "setting_floating.subtitle".localized
    }
    
    enum Setting{
        static let sectionLabel = "setting.section_label".localized
        static let newPillBtn = "setting.new_pill_button".localized
        static let navigationTitle = "setting.navigation_title".localized
        static let alarmSectionTitle = "setting.alarm_section_title".localized

        static let timeSettingTitle = "setting.time_setting_title".localized
        static let timeSettingDefault = "setting.time_setting_default".localized

        static let messageSettingTitle = "setting.message_setting_title".localized
        static let messageSettingDefault = "setting.message_setting_default".localized

        static let messageEditorTitle = "setting.message_editor_title".localized
        static let messageEditorDescription = "setting.message_editor_description".localized
        static let messageEditorPlaceholder = "setting.message_editor_placeholder".localized

        static let newPillCycleTitle = "setting.new_pill_cycle_title".localized
        static let newPillCycleMessage = "setting.new_pill_cycle_message".localized
        static let newPillCycleConfirm = "setting.new_pill_cycle_confirm".localized

        static let successTimeUpdated = "setting.success_time_updated".localized
        static let successMessageUpdated = "setting.success_message_updated".localized
        static let errorTimeUpdateFailed = "setting.error_time_update_failed".localized
        static let errorMessageUpdateFailed = "setting.error_message_update_failed".localized
        static let errorResetFailed = "setting.error_reset_failed".localized

        static let permissionErrorGoToSettings = "setting.permission_error_go_to_settings".localized

    }
    enum Dashboard {
        static let guideTitle = "dashboard.guide_title".localized
        static let guideSubtitle = "dashboard.guide_subtitle".localized
        static let guideConfirmButton = "dashboard.guide_confirm_button".localized

        static let guideTaken = "dashboard.guide_taken".localized
        static let guideTakenDouble = "dashboard.guide_taken_double".localized
        static let guideMissed = "dashboard.guide_missed".localized
        static let taken = "dashboard.taken".localized
        static let takenDouble = "dashboard.taken_double".localized
        static let guideToday = "dashboard.guide_today".localized

        static let takePillButton = "dashboard.take_pill_button".localized
        static let takePillCompleted = "dashboard.take_pill_completed".localized
        static let restPeriod = "dashboard.rest_period".localized
        static let restPeriodTooltip = "dashboard.rest_period_tooltip".localized
        static let progressBeforeStart = "dashboard.progress_before_start".localized
        static func progressDay(_ day: Int) -> String {
            "dashboard.progress_day".localized(with: day)
        }
        static func dayProgressFormat(current: Int, total: Int) -> String {
            "dashboard.day_progress_format".localized(with: current, total)
        }

        static var weekdays: [String] {
            let calendar = Calendar.current
            let symbols = calendar.shortWeekdaySymbols
            return Array(symbols.dropFirst()) + [symbols.first!]
        }
    }

    enum Widget {
        static let configurationDisplayName = "widget.configuration_display_name".localized
        static let configurationDescription = "widget.configuration_description".localized
        static func dayLabel(_ day: Int) -> String {
            "widget.day_label".localized(with: day)
        }
        static let messagePlantGrass = "widget.message_plant_grass".localized
        static let messageSetupPill = "widget.message_setup_pill".localized
        static let messageGrassWaiting = "widget.message_grass_waiting".localized
        static let messageOnePillComplete = "widget.message_one_pill_complete".localized
        static let messageRestTime = "widget.message_rest_time".localized
        static let messageTwoToday = "widget.message_two_today".localized
        static let messageTodayComplete = "widget.message_today_complete".localized
        static let messageOverTwoHours = "widget.message_over_two_hours".localized
        static let messageOverFourHours = "widget.message_over_four_hours".localized
    }

    enum History {
        static let navigationTitle = "history.navigation_title".localized
        static let detailTitle = "history.detail_title".localized
        static let emptyMessage = "history.empty_message".localized
        static let startLabel = "history.start_label".localized
        static let createdLabel = "history.created_label".localized
        static func cycleTitle(_ number: Int, totalDays: Int) -> String {
            "history.cycle_title_format".localized(with: number, totalDays)
        }
        static func activeDaysFormat(_ days: Int) -> String {
            return "history.active_days_format".localized(with: days)
        }
        static func breakDaysFormat(_ days: Int) -> String {
            return "history.break_days_format".localized(with: days)
        }
        static let scheduledTimeLabel = "history.scheduled_time_label".localized
        static func cellMetaFormat(activeDays: Int, breakDays: Int, time: String) -> String {
            return "history.cell_meta_format".localized(with: activeDays, breakDays, time)
        }
    }

    enum Statistics {
        static let myRecordTitle = "statistics.my_record_title".localized
        static let takingPillLabel = "statistics.taking_pill_label".localized
        static let chartTitle = "statistics.chart_title".localized
        static let periodSelectionTitle = "statistics.period_selection_title".localized
        static let categoryOnTime = "statistics.category_on_time".localized
        static let categoryDelayed = "statistics.category_delayed".localized
        static let categoryMissedOrDouble = "statistics.category_missed_or_double".localized
        static let deletedSideEffect = "statistics.deleted_side_effect".localized
        static func dayCount(_ days: Int) -> String {
            "statistics.day_count_format".localized(with: days)
        }
        static func sideEffectCount(_ count: Int) -> String {
            "statistics.side_effect_count_format".localized(with: count)
        }
    }

    enum Message {
        // 기본 메시지
        static let empty = "message.empty".localized
        static let cycleComplete = "message.cycle_complete".localized
        static let setupRequired = "message.setup_required".localized
        static let restPeriod = "message.rest_period".localized
        static let forgotMe = "message.forgot_me".localized
        static let plantTodayGrass = "message.plant_today_grass".localized
        static let plantSteadily = "message.plant_steadily".localized
        static let pillingSearching = "message.pilling_searching".localized
        static let pillingAngry = "message.pilling_angry".localized
        static let takeTwoPills = "message.take_two_pills".localized
        static let grassGrowingWell = "message.grass_growing_well".localized
        static let missedYesterdayTakeTwo = "message.missed_yesterday_take_two".localized
        static let takeWithinTwoHours = "message.take_within_two_hours".localized
        static let needOnePillMore = "message.need_one_pill_more".localized //한알더먹어야해요
        static let takenDelayedOk = "message.taken_delayed_ok".localized
        static let tookTooEarly = "message.took_too_early".localized
        static let seeTomorrow = "message.see_tomorrow".localized
        static let startTakingToday = "message.start_taking_today".localized
        static let startTakingTomorrow = "message.start_taking_tomorrow".localized
        static func daysUntilStart(_ days: Int) -> String {
            return "message.days_until_start".localized(with: days)
        }
        static let onePillMore = "message.one_pill_more".localized //
        static let overTwoHours = "message.over_two_hours".localized
        static let overFourHours = "message.over_four_hours".localized
        static func noRecordForDays(_ days: Int) -> String {
            return "message.no_record_for_days".localized(with: days)
        }

        // 위젯용 메시지
        static let widgetPlantGrass = "widget.message_plant_grass".localized
        static let widgetPlantingComplete = "widget.message_one_pill_complete".localized
        static let widgetGrassWaiting = "widget.message_grass_waiting".localized
        static let widgetRestTime = "widget.message_rest_time".localized
        static let widgetOverTwoHours = "widget.message_over_two_hours".localized
        static let widgetOverFourHours = "widget.message_over_four_hours".localized
    }

    enum Onboarding {
        static let nextButton = "onboarding.next_button".localized
        static let startButton = "onboarding.start_button".localized
        static let page1Title = "onboarding.page1_title".localized
        static let page1Description = "onboarding.page1_description".localized
        static let page2Title = "onboarding.page2_title".localized
        static let page2Description = "onboarding.page2_description".localized
        static let page3Title = "onboarding.page3_title".localized
        static let page3Description = "onboarding.page3_description".localized
    }

    enum Notification {
        static let title = "notification.title".localized
        static let breakPeriodMessage = "notification.break_period".localized
        static let defaultMessage = "notification.default_message".localized
    }

    enum SideEffectTag {
        static let moodDown = "side_effect.mood_down".localized
        static let spotting = "side_effect.spotting".localized
        static let dryMouth = "side_effect.dry_mouth".localized
        static let sectionTitle = "side_effect.section_title".localized
        static let addButton = "side_effect.add_button".localized
        static let manageTitle = "side_effect.manage_title".localized
        static let editTitle = "side_effect.edit_title".localized
        static let doneTitle = "side_effect.done_title".localized
        static let newTagTitle = "side_effect.new_tag_title".localized
        static let newTagMessage = "side_effect.new_tag_message".localized
        static let newTagPlaceholder = "side_effect.new_tag_placeholder".localized
    }

    enum Error {
        static let invalidTimeFormat = "error.invalid_time_format".localized
        static let invalidDateRange = "error.invalid_date_range".localized
        static let unknownError = "error.unknown_error".localized
        static let permissionError = "error.permission_error".localized
        static let notificationPermissionTitle = "error.notification_permission_title".localized
        static let notificationPermissionRequired = "error.notification_permission_required".localized
        static let notificationSettingFailed = "error.notification_setting_failed".localized
        static let invalidTime = "error.invalid_time".localized
        static let pillInfoNotFound = "error.pill_info_not_found".localized
        static let retryLater = "error.retry_later".localized
        static let dataLoadFailed = "error.data_load_failed".localized
    }

    enum TimeSetting {
        static let mainTitle = "time_setting.main_title".localized
        static let subtitle = "time_setting.subtitle".localized
        static let timeButtonTitle = "time_setting.time_button_title".localized
        static let confirmButton = "time_setting.confirm_button".localized
        static let pickerConfirmButton = "time_setting.picker_confirm_button".localized
        static let navigationTitle = "time_setting.navigation_title".localized
    }
}

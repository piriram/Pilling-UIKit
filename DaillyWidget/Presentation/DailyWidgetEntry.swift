import WidgetKit
import SwiftUI

// MARK: - PillingDailyWidgetEntry

struct DailyWidgetEntry: TimelineEntry {
    let date: Date
    let displayData: WidgetDisplayData
    
    static var placeholder: DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            displayData: WidgetDisplayData(
                cycleDay: 1,
                message: "잔디를 심어보세요!",
                iconImageName: "widget_icon_plant",
                backgroundImageName: "widget_background_normal"
            )
        )
    }

    static var empty: DailyWidgetEntry {
        DailyWidgetEntry(
            date: Date(),
            displayData: WidgetDisplayData(
                cycleDay: 0,
                message: "약을 설정해주세요",
                iconImageName: "widget_icon_rest",
                backgroundImageName: "widget_background_normal"
            )
        )
    }
}




import SwiftUI
import WidgetKit

// MARK: - PillingDailyWidgetView

struct DailyWidgetView: View {
    let entry: DailyWidgetEntry
    
    var body: some View {
        
        VStack(spacing: 4) {
            // 상단 아이콘
            Image(entry.displayData.iconImageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
            
            // N일차
            if entry.displayData.cycleDay > 0 {
                Text(AppStrings.Widget.dayLabel(entry.displayData.cycleDay))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // 메시지
            Text(entry.displayData.message)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            
        }
        .containerBackground(for: .widget) {
            Image(entry.displayData.backgroundImageName)
                .resizable()
                .scaledToFill()
        }
        .widgetURL(URL(string: "pillingapp://widget"))
        
    }
}

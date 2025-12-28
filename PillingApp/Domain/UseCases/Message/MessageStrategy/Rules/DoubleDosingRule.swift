import Foundation

final class DoubleDosingRule: MessageRule {
    let priority = 200
    
    func shouldEvaluate(context: MessageContext) -> Bool {
        guard let yesterday = context.yesterdayStatus else {
            return false
        }
        
        let timeSinceMissed = context.currentDate.timeIntervalSince(yesterday.scheduledDate)
        let isNotTaken = !yesterday.isTaken
        let isWithinWindow = timeSinceMissed < TimeThreshold.critical + TimeThreshold.fullyMissed
        
        return isNotTaken && isWithinWindow
    }
    
    func evaluate(context: MessageContext) -> MessageType? {
        guard let todayStatus = context.todayStatus,
              let yesterdayStatus = context.yesterdayStatus else { return nil }
        
        let timeSinceYesterday = context.currentDate.timeIntervalSince(yesterdayStatus.scheduledDate)
        
        if timeSinceYesterday < TimeThreshold.critical + TimeThreshold.fullyMissed {
            if todayStatus.baseStatus == .takenDouble {
                return .takenDoubleComplete
            }

            if !todayStatus.isTaken &&
                (todayStatus.medicalTiming == .onTime ||
                 todayStatus.medicalTiming == .upcoming ||
                 todayStatus.medicalTiming == .tooEarly ||
                 todayStatus.medicalTiming == .slightDelay) {
                return .takingBeforeTwo
            }
        }
        
        if todayStatus.baseStatus == .takenDouble{
            return .takenDoubleComplete
        }
        
        if todayStatus.isTaken && todayStatus.baseStatus != .takenDouble{
            return .morePill
        }
        return nil
    }
}

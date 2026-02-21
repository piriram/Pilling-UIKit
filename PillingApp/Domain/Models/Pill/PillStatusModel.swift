import Foundation

struct PillStatusModel: Codable, Sendable {
    let baseStatus: PillStatus
    let timeContext: TimeContext
    let medicalTiming: MedicalTiming
    let scheduledDate: Date
    let actionDate: Date?

    var isTaken: Bool {
        baseStatus.isTaken
    }

    var requiresAction: Bool {
        return timeContext == .present &&
               medicalTiming != .missed &&
               medicalTiming != .recent &&
               !isTaken &&
               baseStatus != .rest
    }

    var delayMinutes: Int? {
        guard let actionDate = actionDate else { return nil }
        return Int(actionDate.timeIntervalSince(scheduledDate) / 60)
    }

    var canTakeDouble: Bool {
        guard timeContext == .present,
              !isTaken,
              baseStatus == .notTaken else { return false }
        return medicalTiming == .onTime ||
               medicalTiming == .slightDelay
    }
}

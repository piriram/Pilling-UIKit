import Foundation

// MARK: - Request

struct RegisterUserRequest: Encodable {
    let user_id: String
    let device_token: String
}

struct UpdateDeviceTokenRequest: Encodable {
    let device_token: String
}

struct RegisterPillRequest: Encodable {
    let name: String
    let scheduled_time: String
}

struct UpdatePillCycleRequest: Encodable {
    let cycle_start_date: String
    let active_days: Int
    let break_days: Int
    let scheduled_time: String?
}

struct UpdatePillNotificationMessageRequest: Encodable {
    let notification_message: String
}

// MARK: - Response

struct UserResponse: Decodable {
    let user_id: String
}

struct RegisterPillResponse: Decodable {
    let pill_id: String
}

struct ServerPillDTO: Decodable {
    let pill_id: String
    let name: String
    let scheduled_time: String

    func toDomain() -> ServerPill {
        ServerPill(pillID: pill_id, name: name, scheduledTime: scheduled_time)
    }
}

struct PillTakenResponse: Decodable {
    let record_id: String
    let taken_at: String

    func toDomain() -> PillTakenRecord {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: taken_at) ?? Date()
        return PillTakenRecord(recordID: record_id, takenAt: date)
    }
}

import Foundation

enum MedicationAPIError: Error {
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case apiError(code: String, message: String)
    case invalidURL
    case cacheCorrupted
    case regionNotSupported
}

extension MedicationAPIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "네트워크 연결에 실패했습니다: \(error.localizedDescription)"
        case .invalidResponse:
            return "서버 응답이 올바르지 않습니다"
        case .httpError(let statusCode):
            return "서버 오류가 발생했습니다 (코드: \(statusCode))"
        case .decodingError(let error):
            return "데이터 파싱에 실패했습니다: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API 오류 (\(code)): \(message)"
        case .invalidURL:
            return "잘못된 URL입니다"
        case .cacheCorrupted:
            return "캐시 데이터가 손상되었습니다"
        case .regionNotSupported:
            return "현재 지역에서는 지원되지 않는 기능입니다"
        }
    }
}

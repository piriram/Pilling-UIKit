import Foundation

extension String {
    /// 다국어 번역을 가져옵니다
    /// - Returns: 현재 언어로 번역된 문자열
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }

    /// 파라미터가 있는 다국어 번역을 가져옵니다
    /// - Parameters:
    ///   - arguments: 문자열 포맷 파라미터
    /// - Returns: 현재 언어로 번역된 문자열
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}

// MARK: - 사용 예시
/*
 // 기본 사용
 let title = "dashboard.title".localized  // "대시보드" 또는 "Dashboard"

 // 파라미터 있는 번역
 // Localizable.strings: "pill.count" = "%d개의 약";
 let message = "pill.count".localized(with: 5)  // "5개의 약"
 */

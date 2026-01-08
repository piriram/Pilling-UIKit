import Foundation

struct DosageParser {

    static func parse(dosageText: String) -> (takingDays: Int, breakDays: Int) {
        let normalizedText = dosageText.lowercased()
            .replacingOccurrences(of: " ", with: "")

        var takingDays = 21
        var breakDays = 7

        if let takingMatch = extractDays(from: normalizedText, patterns: ["(\\d+)일복용", "(\\d+)일투여", "(\\d+)일간복용", "(\\d+)일간투여"]) {
            takingDays = takingMatch
        }

        if let breakMatch = extractDays(from: normalizedText, patterns: ["(\\d+)일휴약", "(\\d+)일쉬", "(\\d+)일간휴약", "(\\d+)일중단"]) {
            breakDays = breakMatch
        }

        if normalizedText.contains("26") && normalizedText.contains("2") {
            takingDays = 26
            breakDays = 2
        } else if normalizedText.contains("24") && normalizedText.contains("4") {
            takingDays = 24
            breakDays = 4
        } else if normalizedText.contains("21") && normalizedText.contains("7") {
            takingDays = 21
            breakDays = 7
        } else if normalizedText.contains("28") && normalizedText.contains("연속") {
            takingDays = 28
            breakDays = 0
        }

        return (takingDays, breakDays)
    }

    private static func extractDays(from text: String, patterns: [String]) -> Int? {
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
               match.numberOfRanges > 1 {
                let numberRange = match.range(at: 1)
                if let range = Range(numberRange, in: text),
                   let days = Int(text[range]) {
                    return days
                }
            }
        }
        return nil
    }
}

import UIKit

// MARK: - Presentation/Common/Constants/AppColor.swift
public enum AppColor {
    public static let bg = UIColor(hexString: "FFFFFF")
    public static let card = UIColor.secondarySystemBackground
    public static let pillGreen800 = UIColor(hexString: "7EDD1C")
    public static let pillGreen700 = UIColor(hexString: "61AF0D")
    public static let pillGreen600 = UIColor(hexString: "AFF466")
    public static let pillGreen400 = UIColor.systemGreen.withAlphaComponent(0.4)
    public static let pillGreen300 = UIColor(hexString: "BCF57F")
    public static let pillGreen200 = UIColor(hexString: "AFF466")
    public static let pillGreen100 = UIColor(hexString: "E9FCD4")
    public static let pillBrown = UIColor(hexString: "B8A07D")
    public static let notYetGray = UIColor(hexString: "3C3C43").withAlphaComponent(0.18)
    public static let pillWhite = UIColor.white
    public static let pillBorder = UIColor(hexString: "7EDD1C")
    public static let textBlack = UIColor(hexString: "222222")
    public static let black = UIColor(hexString: "242E2C")

    public static let secondary = UIColor(hexString: "3C3C43").withAlphaComponent(0.6)
    public static let weekdayText = UIColor(hexString: "3C3C43").withAlphaComponent(0.3)
    public static let borderGray = UIColor(hexString: "D9D9D9")
    public static let textGray = UIColor(hexString: "606060")
    public static let cheveronGray = UIColor(hexString: "A3A3A3")
    public static let grayBackground = UIColor(hexString: "F7F7F7")
    public static let gray700 = UIColor(hexString: "4B4B4B")
    public static let gray800 = UIColor(hexString: "474747")
    public static let green800 = UIColor(hexString: "49850A")
    public static let gray600 = UIColor(hexString: "757575")
    public static let gray400 = UIColor(hexString: "A3A3A3")
    public static let gray300 = UIColor(hexString: "BABABA")
    public static let gray100 = UIColor(hexString: "E8E8E8")

    public static let breakPeriodBg = UIColor(hexString: "E8DAC5")
    public static let breakPeriodText = UIColor(hexString: "A58351")
}




extension UIColor {
    public convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        guard hexString.count == 6 || hexString.count == 8, let hexValue = UInt64(hexString, radix: 16) else {
            return nil
        }
        let r, g, b, a: CGFloat
        if hexString.count == 6 {
            r = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexValue & 0x0000FF) / 255.0
            a = 1.0
        } else {
            r = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexValue & 0x000000FF) / 255.0
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    public convenience init(hexString s0: String) {
        var s = s0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        let isValidLength = (s.count == 6 || s.count == 8)
        if isValidLength, let value = UInt64(s, radix: 16) {
            let r, g, b, a: CGFloat
            if s.count == 6 {
                r = CGFloat((value & 0xFF0000) >> 16) / 255.0
                g = CGFloat((value & 0x00FF00) >> 8) / 255.0
                b = CGFloat(value & 0x0000FF) / 255.0
                a = 1.0
            } else {
                r = CGFloat((value & 0xFF000000) >> 24) / 255.0
                g = CGFloat((value & 0x00FF0000) >> 16) / 255.0
                b = CGFloat((value & 0x0000FF00) >> 8) / 255.0
                a = CGFloat(value & 0x000000FF) / 255.0
            }
            self.init(red: r, green: g, blue: b, alpha: a)
        } else {
            self.init(cgColor: UIColor.black.cgColor)
        }
    }
}


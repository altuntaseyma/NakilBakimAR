import Foundation

/// TC Kimlik numarası doğrulama — Türkiye Cumhuriyeti Mod10 algoritması
func isValidTcNo(_ tc: String) -> Bool {
    let cleaned = tc.filter(\.isNumber)
    guard cleaned.count == 11, cleaned.first != "0" else { return false }
    let digits = cleaned.compactMap(\.wholeNumberValue)
    guard digits.count == 11 else { return false }

    let oddSum  = digits[0] + digits[2] + digits[4] + digits[6] + digits[8]
    let evenSum = digits[1] + digits[3] + digits[5] + digits[7]
    let check10 = ((oddSum * 7) - evenSum) % 10
    let check11 = digits.prefix(10).reduce(0, +) % 10

    return check10 == digits[9] && check11 == digits[10]
}

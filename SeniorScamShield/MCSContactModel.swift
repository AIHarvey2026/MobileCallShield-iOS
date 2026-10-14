import Foundation

struct MCSContactModel: Identifiable, Codable {
    let id: Int?
    let name: String
    let phoneNumber: String
    let isTrusted: Bool
}

extension String {
    var normalizedPhoneNumber: String {
        let digits = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if digits.count == 11 && digits.hasPrefix("1") {
            return String(digits.dropFirst())
        }
        return digits
    }
}

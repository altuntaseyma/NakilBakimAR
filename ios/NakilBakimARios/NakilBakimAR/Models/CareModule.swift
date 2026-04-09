import Foundation

struct CareModule: Codable, Identifiable {
    let id: Int
    let name: String
    var isEnabled: Bool
}

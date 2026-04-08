import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let fullName: String
    let role: String
}

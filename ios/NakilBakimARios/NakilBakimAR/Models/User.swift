import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let fullName: String
    let role: String
    let patientTc: String?   // Yalnızca hasta rolünde dolu gelir
}

import Foundation

struct PatientProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let diagnosis: String?
    var transplantDate: String?
    let isActive: Bool
    let nurseId: UUID?
    let fullName: String?
    let email: String?
    let carePhase: String?
    let lastVitalRecordedAt: String?
}

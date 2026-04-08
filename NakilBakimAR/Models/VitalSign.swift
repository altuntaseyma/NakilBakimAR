import Foundation

struct VitalSign: Codable, Identifiable {
    let id: UUID
    let bodyTemperature: Double?
    let bloodPressureSystolic: Int?
    let bloodPressureDiastolic: Int?
    let heartRate: Int?
    let oxygenSaturation: Int?
    let notes: String?
    let sharedWithPatient: Bool
}

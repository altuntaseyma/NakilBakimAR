import Foundation

struct VitalSign: Codable, Identifiable {
    let id: UUID
    let recordedAt: String?
    let bodyTemperature: Double?
    let bloodPressureSystolic: Int?
    let bloodPressureDiastolic: Int?
    let heartRate: Int?
    let oxygenSaturation: Int?
    let notes: String?
    let sharedWithPatient: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case recordedAt
        case bodyTemperature
        case bloodPressureSystolic
        case bloodPressureDiastolic
        case heartRate
        case oxygenSaturation
        case notes
        case sharedWithPatient
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        recordedAt = try container.decodeIfPresent(String.self, forKey: .recordedAt)
        bodyTemperature = try Self.decodeFlexibleDouble(container, key: .bodyTemperature)
        bloodPressureSystolic = try Self.decodeFlexibleInt(container, key: .bloodPressureSystolic)
        bloodPressureDiastolic = try Self.decodeFlexibleInt(container, key: .bloodPressureDiastolic)
        heartRate = try Self.decodeFlexibleInt(container, key: .heartRate)
        oxygenSaturation = try Self.decodeFlexibleInt(container, key: .oxygenSaturation)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        sharedWithPatient = try container.decode(Bool.self, forKey: .sharedWithPatient)
    }

    init(
        id: UUID,
        recordedAt: String?,
        bodyTemperature: Double?,
        bloodPressureSystolic: Int?,
        bloodPressureDiastolic: Int?,
        heartRate: Int?,
        oxygenSaturation: Int?,
        notes: String?,
        sharedWithPatient: Bool
    ) {
        self.id = id
        self.recordedAt = recordedAt
        self.bodyTemperature = bodyTemperature
        self.bloodPressureSystolic = bloodPressureSystolic
        self.bloodPressureDiastolic = bloodPressureDiastolic
        self.heartRate = heartRate
        self.oxygenSaturation = oxygenSaturation
        self.notes = notes
        self.sharedWithPatient = sharedWithPatient
    }

    private static func decodeFlexibleDouble(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Double? {
        if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return Double(stringValue)
        }
        return nil
    }

    private static func decodeFlexibleInt(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Int? {
        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return Int(stringValue)
        }
        return nil
    }
}

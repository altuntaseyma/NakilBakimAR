import Foundation

struct ScenarioSummary: Codable {
    let totalDecisions: Int
    let correctDecisions: Int
    let avgDurationSec: Int
    let successRate: Int

    private enum CodingKeys: String, CodingKey {
        case totalDecisions
        case correctDecisions
        case avgDurationSec
        case successRate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalDecisions = try Self.decodeFlexibleInt(container, key: .totalDecisions)
        correctDecisions = try Self.decodeFlexibleInt(container, key: .correctDecisions)
        avgDurationSec = try Self.decodeFlexibleInt(container, key: .avgDurationSec)
        successRate = try Self.decodeFlexibleInt(container, key: .successRate)
    }

    private static func decodeFlexibleInt(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Int {
        if let value = try container.decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let stringValue = try container.decodeIfPresent(String.self, forKey: key),
           let value = Int(stringValue) {
            return value
        }
        return 0
    }
}

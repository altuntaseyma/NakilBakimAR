import Foundation

struct ScenarioSummary: Codable {
    let totalDecisions: Int
    let correctDecisions: Int
    let avgDurationSec: Int
    let successRate: Int
}

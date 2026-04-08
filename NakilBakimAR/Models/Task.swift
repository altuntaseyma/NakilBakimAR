import Foundation

struct TaskItem: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let type: String
    let title: String
    let description: String?
    let scheduledTime: Date?
    var isCompleted: Bool
}

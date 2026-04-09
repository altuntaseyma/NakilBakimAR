import Foundation

struct TaskItem: Codable, Identifiable {
    let id: UUID
    let patientId: UUID
    let type: String
    let title: String
    let description: String?
    let scheduledTime: String?
    var isCompleted: Bool
}

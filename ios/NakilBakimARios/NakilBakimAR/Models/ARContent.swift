import Foundation

struct ARContent: Codable, Identifiable {
    let id: Int
    let markerImageUrl: String?
    let modelUrl: String?
    let animationType: String?
    let taskType: String?
}

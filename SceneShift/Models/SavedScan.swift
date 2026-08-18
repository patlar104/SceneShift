import Foundation

struct SavedScan: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date
    let roomFileName: String
    var usdzFileName: String?
}

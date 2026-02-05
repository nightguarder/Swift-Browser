import Foundation

struct HistoryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let url: URL
    let title: String?
    let visitDate: Date
}

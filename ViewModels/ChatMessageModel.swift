import Foundation

struct ChatMessageModel: Identifiable, Codable {
    enum Sender: String, Codable {
        case user
        case assistant
    }

    let id: UUID
    let sender: Sender
    let text: String
    let timestamp: Date

    init(
        id: UUID = UUID(),
        sender: Sender,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
    }
}

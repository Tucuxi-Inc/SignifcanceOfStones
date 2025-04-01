import Foundation
import SwiftData

@Model
final class ChatMessage: Identifiable {
    var id: UUID = UUID()
    var content: String = ""
    var role: MessageRole = MessageRole.user
    var timestamp: Date = Date()
    var isDeleted: Bool = false
    var chat: Chat?
    
    init(id: UUID = UUID(), content: String, role: MessageRole, timestamp: Date = Date(), isDeleted: Bool = false) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.isDeleted = isDeleted
    }
} 
import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<ChatMessage> { message in !message.isDeleted },
        sort: [SortDescriptor(\ChatMessage.timestamp)]
    ) private var chatHistory: [ChatMessage]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(chatHistory) { message in
                    ChatBubble(content: message.content, isUser: message.role == .user)
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteChat(message)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }
    
    private func deleteChat(_ message: ChatMessage) {
        message.isDeleted = true
        try? modelContext.save()
    }
} 
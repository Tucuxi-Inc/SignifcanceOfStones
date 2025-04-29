import SwiftUI

struct ChatBubble: View {
    let content: String
    let isUser: Bool
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(content)
                .padding()
                .background(isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .textSelection(.enabled)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = content
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    
                    ShareLink(
                        item: content,
                        preview: SharePreview("Chat Message")
                    )
                }
            
            if !isUser { Spacer() }
        }
    }
} 
import SwiftUI
import SwiftData

@MainActor
class MindViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var isProcessing: Bool = false
    @Published var error: String?
    @Published var showingChatHistory = false
    
    private let mindSystem: MindSystem
    private let modelContext: ModelContext
    
    @Published var currentChat: Chat
    
    // Add new property to track current agent activity
    @Published var processingState: ProcessingState = .idle
    
    // Define processing states
    enum ProcessingState {
        case idle
        case cortexAnalyzing
        case seerScanning
        case oracleEvaluating
        case houseConsidering
        case prudenceAssessing
        case conscienceWeighing
        case integrating
        
        var description: String {
            switch self {
            case .idle:
                return ""
            case .cortexAnalyzing:
                return "Analyzing emotional context and core meaning..."
            case .seerScanning:
                return "Scanning for patterns and future implications..."
            case .oracleEvaluating:
                return "Evaluating strategic possibilities..."
            case .houseConsidering:
                return "Considering practical implementation..."
            case .prudenceAssessing:
                return "Assessing risks and boundaries..."
            case .conscienceWeighing:
                return "Weighing ethical implications..."
            case .integrating:
                return "Integrating insights into final response..."
            }
        }
        
        var icon: String {
            switch self {
            case .idle: return ""
            case .cortexAnalyzing: return "brain.head.profile"
            case .seerScanning: return "sparkles.tv"
            case .oracleEvaluating: return "chart.line.uptrend.xyaxis"
            case .houseConsidering: return "house"
            case .prudenceAssessing: return "exclamationmark.shield"
            case .conscienceWeighing: return "heart.circle"
            case .integrating: return "arrow.triangle.merge"
            }
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Try to fetch existing settings
        let descriptor = FetchDescriptor<AISettings>()
        let existingSettings = try? modelContext.fetch(descriptor).first
        
        let settings = existingSettings ?? {
            let newSettings = AISettings(
                model: AISettings.Model.defaultModel,
                apiKey: APIConfig.openAIKey,
                defaultTemperature: 0.7,
                debugMode: true,
                logResponses: true
            )
            modelContext.insert(newSettings)
            return newSettings
        }()
        
        self.currentChat = Chat()
        self.mindSystem = MindSystem(settings: settings, modelContext: modelContext)
        
        modelContext.insert(currentChat)
    }
    
    func sendMessage() async {
        guard !userInput.isEmpty else { return }
        
        let userMessage = ChatMessage(content: userInput, role: .user)
        modelContext.insert(userMessage)
        
        // Initialize messages array if nil and set inverse relationship
        if currentChat.messages == nil {
            currentChat.messages = []
        }
        currentChat.messages?.append(userMessage)
        userMessage.chat = currentChat
        
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        do {
            let response = try await mindSystem.processInput(userInput, chat: currentChat) { state in
                Task { @MainActor in
                    self.processingState = state
                }
            }
            
            await MainActor.run {
                let assistantMessage = ChatMessage(content: response, role: .assistant)
                modelContext.insert(assistantMessage)
                currentChat.messages?.append(assistantMessage)
                assistantMessage.chat = currentChat
                
                userInput = ""
                
                if (currentChat.messages?.count ?? 0) == 2 {
                    currentChat.title = userMessage.content
                }
                
                try? modelContext.save()
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
            }
        }
        
        await MainActor.run {
            processingState = .idle
            isProcessing = false
        }
    }
    
    func startNewChat() {
        let newChat = Chat()
        modelContext.insert(newChat)
        currentChat = newChat
        try? modelContext.save()
    }
    
    func switchToChat(_ chat: Chat) {
        currentChat = chat
    }
    
    func deleteChat(_ chat: Chat) {
        modelContext.delete(chat)
        if chat.id == currentChat.id {
            startNewChat()
        }
        try? modelContext.save()
    }
}

struct MindChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    @StateObject private var viewModel: MindViewModel
    @State private var showingSettings = false
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: MindViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                chatList
                    .padding(.bottom, 80)
                
                inputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 4) {
                    Text("Significance of Stones")
                        .font(.title2)
                        .padding(.top, 32)
                    Text("AI Mind")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("New Chat") {
                        viewModel.startNewChat()
                    }
                    
                    Button("Chat History") {
                        viewModel.showingChatHistory = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingChatHistory) {
            ChatHistoryView(chats: chats, onSelect: { chat in
                viewModel.currentChat = chat
                viewModel.showingChatHistory = false
            }, onDelete: viewModel.deleteChat)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    Color.clear.frame(height: 8)
                    
                    ForEach(viewModel.currentChat.messages?.sorted(by: { $0.timestamp < $1.timestamp }) ?? []) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isProcessing {
                        HStack {
                            if !viewModel.processingState.icon.isEmpty {
                                Image(systemName: viewModel.processingState.icon)
                                    .font(.title2)
                            }
                            Text(viewModel.processingState.description)
                                .italic()
                            Spacer()
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .id(UUID())
                    }
                }
                .padding()
                .onChange(of: viewModel.currentChat.messages?.count ?? 0) { oldCount, newCount in
                    if let lastMessage = viewModel.currentChat.messages?.sorted(by: { $0.timestamp < $1.timestamp }).last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private var inputBar: some View {
        VStack(spacing: 8) {
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                TextField("Type a message...", text: $viewModel.userInput)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.userInput.isEmpty || viewModel.isProcessing)
                .padding(.trailing)
            }
            .padding([.leading, .bottom])
        }
    }
}

struct ChatHistoryView: View {
    let chats: [Chat]
    let onSelect: (Chat) -> Void
    let onDelete: (Chat) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(chats) { chat in
                    Button {
                        onSelect(chat)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(chat.title)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            if let firstMessage = chat.messages?.first {
                                Text(firstMessage.content)
                                    .lineLimit(1)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(chat.timestamp.formatted())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        onDelete(chats[index])
                    }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: UIScreen.main.bounds.width * 0.1)
                Text(message.content)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Spacer(minLength: UIScreen.main.bounds.width * 0.1)
            }
        }
    }
}

@MainActor
private func createPreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Chat.self, ChatMessage.self, ChatAnalysis.self,
            AgentResponse.self, EmotionMeasurement.self,
            AgentSettings.self, AISettings.self,
        configurations: config
    )
    
    // Create AISettings
    let aiSettings = AISettings(
        model: AISettings.Model.defaultModel,
        apiKey: APIConfig.openAIKey,
        defaultTemperature: 0.7,
        debugMode: true,
        logResponses: true
    )
    container.mainContext.insert(aiSettings)
    aiSettings.agentSettings = []
    
    // Create agent settings
    let orderedTypes: [AgentType] = [
        .cortex,   // 1. Basic cognition
        .seer,     // 2. Pattern recognition
        .oracle,   // 3. Strategic thinking
        .house,    // 4. Implementation
        .prudence, // 5. Risk assessment
        .conscience // 6. Moral judgment
    ]
    
    for agentType in orderedTypes {
        let settings = AgentSettings(
            agentType: agentType,
            model: AISettings.Model.defaultModel,
            temperature: agentType.defaultTemperature
        )
        container.mainContext.insert(settings)
        settings.aiSettings = aiSettings
        aiSettings.agentSettings?.append(settings)
    }
    
    // Create a sample chat with messages
    let chat = Chat(title: "Preview Chat")
    container.mainContext.insert(chat)
    chat.messages = []
    
    let messages = [
        ChatMessage(content: "How can I stay motivated?", role: .user),
        ChatMessage(content: "That's a great question! Let me help you explore some strategies...", role: .assistant)
    ]
    
    for message in messages {
        container.mainContext.insert(message)
        message.chat = chat
        chat.messages?.append(message)
    }
    
    try? container.mainContext.save()
    return container
}

#Preview {
    @MainActor in
    let container = createPreviewContainer()
    NavigationStack {
        MindChatView(modelContext: container.mainContext)
            .modelContainer(container)
    }
} 
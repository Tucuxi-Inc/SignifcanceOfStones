//
//  SignifcanceOfStonesApp.swift
//  SignifcanceOfStones
//
//  Created by Kevin Keller on 1/17/25.
//

import SwiftUI
import SwiftData

@main
struct SignifcanceOfStonesApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Chat.self,
                ChatMessage.self,
                ChatAnalysis.self,
                AgentResponse.self,
                EmotionMeasurement.self,
                AgentSettings.self,
                AISettings.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: modelConfiguration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

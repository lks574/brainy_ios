//
//  brainy_iosApp.swift
//  brainy_ios
//
//  Created by KyungSeok Lee on 7/17/25.
//

import SwiftUI
import SwiftData

@main
struct brainy_iosApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            QuizQuestion.self,
            QuizResult.self,
            QuizSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

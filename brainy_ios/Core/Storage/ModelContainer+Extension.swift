import Foundation
import SwiftData

extension ModelContainer {
    /// Brainy 앱의 기본 ModelContainer를 생성합니다
    static func brainyContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            QuizQuestion.self,
            QuizResult.self,
            QuizSession.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    /// 테스트용 인메모리 ModelContainer를 생성합니다
    static func brainyTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            QuizQuestion.self,
            QuizResult.self,
            QuizSession.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}
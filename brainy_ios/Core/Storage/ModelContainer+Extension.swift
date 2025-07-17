import Foundation
import SwiftData

extension ModelContainer {
    /// 공유 ModelContainer 인스턴스
    static let shared: ModelContainer = {
        do {
            return try brainyContainer()
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }()
    
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
    
    /// Preview용 ModelContainer
    static let preview: ModelContainer = {
        do {
            return try brainyTestContainer()
        } catch {
            fatalError("Preview ModelContainer 생성 실패: \(error)")
        }
    }()
}
import Foundation
import SwiftData

@Model
class User {
    @Attribute(.unique) var id: String
    var email: String?
    var displayName: String
    var authProvider: AuthProvider
    var createdAt: Date
    var lastSyncAt: Date?
    
    @Relationship(deleteRule: .cascade) var quizResults: [QuizResult] = []
    
    init(id: String, email: String? = nil, displayName: String, authProvider: AuthProvider) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.authProvider = authProvider
        self.createdAt = Date()
    }
}
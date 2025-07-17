import Foundation

enum AuthProvider: String, CaseIterable, Codable, Sendable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}
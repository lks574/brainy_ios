import Foundation

enum AuthProvider: String, CaseIterable, Codable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}
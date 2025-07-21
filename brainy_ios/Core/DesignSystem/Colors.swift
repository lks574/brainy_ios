import SwiftUI

extension Color {

    // MARK: - Semantic Colors
    static let brainyError = Color.red
    static let brainyWarning = Color.orange
    static let brainyInfo = Color.blue
    
    // MARK: - Quiz Colors
    static let brainyCorrect = Color("BrainySuccess")
    static let brainyIncorrect = Color.red
    static let brainySelected = Color("BrainyPrimary")
    static let brainyUnselected = Color("BrainyTextSecondary")
}

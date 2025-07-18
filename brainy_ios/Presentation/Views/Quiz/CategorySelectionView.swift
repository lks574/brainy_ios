import SwiftUI

/// 카테고리 선택 화면 (임시 구현)
struct CategorySelectionView: View {
    @ObservedObject var coordinator: AppCoordinator
    let quizMode: QuizMode
    
    var body: some View {
        VStack(spacing: 32) {
            Text("카테고리 선택")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
            
            Text("퀴즈 모드: \(quizMode.rawValue)")
                .font(.brainyBody)
                .foregroundColor(.brainyTextSecondary)
            
            Text("이 화면은 Task 8에서 구현됩니다")
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
                .padding()
                .background(Color.brainyCardBackground)
                .cornerRadius(12)
            
            Spacer()
            
            BrainyButton("뒤로 가기", style: .secondary) {
                coordinator.navigateBack()
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
    }
}


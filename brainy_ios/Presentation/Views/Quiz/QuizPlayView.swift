import SwiftUI

/// 퀴즈 플레이 화면 (임시 구현)
struct QuizPlayView: View {
    @State private var coordinator: AppCoordinator
    let category: QuizCategory
    let mode: QuizMode
    
    init(coordinator: AppCoordinator, category: QuizCategory, mode: QuizMode) {
        self._coordinator = State(initialValue: coordinator)
        self.category = category
        self.mode = mode
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("퀴즈 플레이")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
            
            VStack(spacing: 8) {
                Text("카테고리: \(category.rawValue)")
                    .font(.brainyBody)
                    .foregroundColor(.brainyTextSecondary)
                
                Text("모드: \(mode.rawValue)")
                    .font(.brainyBody)
                    .foregroundColor(.brainyTextSecondary)
            }
            
            Text("이 화면은 Task 10에서 구현됩니다")
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

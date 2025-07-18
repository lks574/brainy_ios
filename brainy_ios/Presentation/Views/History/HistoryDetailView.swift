import SwiftUI

/// 히스토리 상세 화면 (임시 구현)
struct HistoryDetailView: View {
    @State private var coordinator: AppCoordinator
    let session: QuizSession
    
    init(coordinator: AppCoordinator, session: QuizSession) {
        self._coordinator = State(initialValue: coordinator)
        self.session = session
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("히스토리 상세")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
            
            Text("세션 ID: \(session.id)")
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
            
            Text("이 화면은 Task 12에서 구현됩니다")
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

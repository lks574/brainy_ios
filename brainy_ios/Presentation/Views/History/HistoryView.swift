import SwiftUI

/// 히스토리 화면 (임시 구현)
struct HistoryView: View {
    @State private var coordinator: AppCoordinator
    
    init(coordinator: AppCoordinator) {
        self._coordinator = State(initialValue: coordinator)
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("퀴즈 히스토리")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
            
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

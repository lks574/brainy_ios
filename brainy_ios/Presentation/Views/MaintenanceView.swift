import SwiftUI

/// 점검 모드 화면
struct MaintenanceView: View {
    @State private var isRetrying = false
    let onRetry: () async -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 점검 아이콘
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 80))
                .foregroundColor(.brainySecondary)
            
            // 점검 메시지
            VStack(spacing: 16) {
                Text("서비스 점검 중")
                    .font(.brainyTitle)
                    .foregroundColor(.brainyText)
                
                Text("더 나은 서비스 제공을 위해\n잠시 점검 중입니다.")
                    .font(.brainyBody)
                    .foregroundColor(.brainyTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            // 재시도 버튼
            BrainyButton(
                isRetrying ? "확인 중..." : "다시 확인",
                style: .primary,
                isEnabled: !isRetrying
            ) {
                await retryCheck()
            }
            .padding(.horizontal, 32)
            
            // 안내 텍스트
            Text("점검이 완료되면 자동으로 서비스가 재개됩니다.")
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
    }
    
    // MARK: - Private Methods
    
    private func retryCheck() async {
        isRetrying = true
        
        // 최소 1초 대기 (사용자 경험)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await onRetry()
        
        isRetrying = false
    }
}

// MARK: - Preview

#if DEBUG
struct MaintenanceView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceView {
            // Preview용 빈 클로저
        }
    }
}
#endif
import SwiftUI

/// 퀴즈 결과 화면 (임시 구현)
struct QuizResultView: View {
    @State private var coordinator: AppCoordinator
    @StateObject private var adManager = AdMobManager.shared
    @State private var shouldShowAd = false
    @State private var adShown = false
    
    let session: QuizSession
    
    init(coordinator: AppCoordinator, session: QuizSession) {
        self._coordinator = State(initialValue: coordinator)
        self.session = session
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Text("퀴즈 결과")
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
            
            VStack(spacing: 12) {
                BrainyButton("다시 퀴즈하기", style: .primary) {
                    coordinator.navigateToQuizModeSelection()
                }
                
                BrainyButton("뒤로 가기", style: .secondary) {
                    coordinator.navigateBack()
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
        .onAppear {
            // 퀴즈 완료 후 광고 표시 (광고가 로드되어 있을 때만)
            if adManager.isInterstitialAdAvailable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    shouldShowAd = true
                }
            } else {
                // 광고가 로드되지 않은 경우 로드 시도
                adManager.loadInterstitialAd()
                adShown = true // 광고 없이 진행
            }
        }
        .showInterstitialAd(when: shouldShowAd && !adShown) {
            // 광고 표시 성공
            adShown = true
            shouldShowAd = false
            print("Interstitial ad shown successfully after quiz completion")
        } onFailed: {
            // 광고 표시 실패 - 정상 진행
            adShown = true
            shouldShowAd = false
            print("Failed to show interstitial ad, continuing normally")
        }
    }
}

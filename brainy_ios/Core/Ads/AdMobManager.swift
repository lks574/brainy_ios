import Foundation
import GoogleMobileAds
import SwiftUI

/// AdMob 광고 관리자
@MainActor
class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()
    
    @Published var isAdLoaded: Bool = false
    @Published var isAdLoading: Bool = false
    @Published var adError: String?
    
    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    private var rewardedAdCompletion: ((Bool, GADAdReward?) -> Void)?
    
    // Test Ad Unit IDs (실제 배포시에는 실제 Ad Unit ID로 변경 필요)
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ID
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Test ID
    
    private override init() {
        super.init()
        initializeAdMob()
    }
    
    /// AdMob 초기화
    private func initializeAdMob() {
        GADMobileAds.sharedInstance().start { [weak self] status in
            Task { @MainActor in
                print("AdMob initialized with status: \(status.adapterStatusesByClassName)")
                self?.loadInterstitialAd()
            }
        }
    }
    
    /// 전면 광고 로드
    func loadInterstitialAd() {
        guard !isAdLoading else { return }
        
        isAdLoading = true
        adError = nil
        
        let request = GADRequest()
        
        GADInterstitialAd.load(withAdUnitID: interstitialAdUnitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                self.isAdLoading = false
                
                if let error = error {
                    self.adError = "전면 광고 로드 실패: \(error.localizedDescription)"
                    self.isAdLoaded = false
                    print("Failed to load interstitial ad: \(error)")
                    return
                }
                
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                self.isAdLoaded = true
                print("Interstitial ad loaded successfully")
            }
        }
    }
    
    /// 보상형 광고 로드
    func loadRewardedAd() {
        let request = GADRequest()
        
        GADRewardedAd.load(withAdUnitID: rewardedAdUnitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    print("Failed to load rewarded ad: \(error)")
                    return
                }
                
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                print("Rewarded ad loaded successfully")
            }
        }
    }
    
    /// 전면 광고 표시
    func showInterstitialAd(from viewController: UIViewController? = nil, completion: @escaping (Bool) -> Void) {
        guard let interstitialAd = interstitialAd else {
            print("Interstitial ad not loaded")
            completion(false)
            return
        }
        
        guard let rootViewController = viewController ?? getRootViewController() else {
            print("No root view controller found")
            completion(false)
            return
        }
        
        interstitialAd.present(fromRootViewController: rootViewController)
        
        // 광고 표시 후 다음 광고 미리 로드
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadInterstitialAd()
        }
        
        completion(true)
    }
    
    /// 보상형 광고 표시
    func showRewardedAd(from viewController: UIViewController? = nil, completion: @escaping (Bool, GADAdReward?) -> Void) {
        guard let rewardedAd = rewardedAd else {
            print("Rewarded ad not loaded")
            completion(false, nil)
            return
        }
        
        guard let rootViewController = viewController ?? getRootViewController() else {
            print("No root view controller found")
            completion(false, nil)
            return
        }
        
        // Store completion for later use in delegate methods
        self.rewardedAdCompletion = completion
        
        rewardedAd.present(fromRootViewController: rootViewController) {
            // This closure is called when the user earns a reward
            // According to Google Mobile Ads SDK, this closure receives no parameters
            // The reward information is available through the ad's adReward property
            let reward = rewardedAd.adReward
            self.rewardedAdCompletion?(true, reward)
            self.rewardedAdCompletion = nil
        }
        
        // 광고 표시 후 다음 광고 미리 로드
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.loadRewardedAd()
        }
    }
    
    /// 루트 뷰 컨트롤러 가져오기
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
    
    /// 광고 사용 가능 여부 확인
    var isInterstitialAdAvailable: Bool {
        return interstitialAd != nil
    }
    
    var isRewardedAdAvailable: Bool {
        return rewardedAd != nil
    }
    
    /// 에러 메시지 클리어
    func clearError() {
        adError = nil
    }
}

// MARK: - GADFullScreenContentDelegate

extension AdMobManager: GADFullScreenContentDelegate {
    nonisolated func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content")
    }
    
    nonisolated func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content")
        
        // Capture ad type information before entering Task block
        let isInterstitialAd = ad is GADInterstitialAd
        let isRewardedAd = ad is GADRewardedAd
        
        Task { @MainActor in
            // 전면 광고가 닫힌 후 새로운 광고 로드
            if isInterstitialAd {
                self.interstitialAd = nil
                self.isAdLoaded = false
                self.loadInterstitialAd()
            } else if isRewardedAd {
                // If rewarded ad was dismissed without earning reward
                if let completion = self.rewardedAdCompletion {
                    completion(false, nil)
                    self.rewardedAdCompletion = nil
                }
                self.rewardedAd = nil
                self.loadRewardedAd()
            }
        }
    }
    
    nonisolated func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present full screen content: \(error)")
        
        // Capture ad type information and error message before entering Task block
        let isInterstitialAd = ad is GADInterstitialAd
        let isRewardedAd = ad is GADRewardedAd
        let errorMessage = "광고 표시 실패: \(error.localizedDescription)"
        
        Task { @MainActor in
            self.adError = errorMessage
            
            // 실패한 광고 정리 및 새로운 광고 로드
            if isInterstitialAd {
                self.interstitialAd = nil
                self.isAdLoaded = false
                self.loadInterstitialAd()
            } else if isRewardedAd {
                // If rewarded ad failed to present
                if let completion = self.rewardedAdCompletion {
                    completion(false, nil)
                    self.rewardedAdCompletion = nil
                }
                self.rewardedAd = nil
                self.loadRewardedAd()
            }
        }
    }
}

// MARK: - SwiftUI Integration

/// SwiftUI에서 AdMob 광고를 표시하기 위한 뷰 모디파이어
struct AdMobInterstitialModifier: ViewModifier {
    @StateObject private var adManager = AdMobManager.shared
    @State private var showingAd = false
    
    let shouldShowAd: Bool
    let onAdShown: () -> Void
    let onAdFailed: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: shouldShowAd) { _, newValue in
                if newValue {
                    showInterstitialAd()
                }
            }
    }
    
    private func showInterstitialAd() {
        guard !showingAd else { return }
        showingAd = true
        
        adManager.showInterstitialAd { success in
            showingAd = false
            if success {
                onAdShown()
            } else {
                onAdFailed()
            }
        }
    }
}

extension View {
    /// 전면 광고를 표시하는 뷰 모디파이어
    func showInterstitialAd(
        when shouldShow: Bool,
        onShown: @escaping () -> Void = {},
        onFailed: @escaping () -> Void = {}
    ) -> some View {
        modifier(AdMobInterstitialModifier(
            shouldShowAd: shouldShow,
            onAdShown: onShown,
            onAdFailed: onFailed
        ))
    }
}

/// 보상형 광고를 위한 뷰 모디파이어
struct AdMobRewardedModifier: ViewModifier {
    @StateObject private var adManager = AdMobManager.shared
    @State private var showingAd = false
    
    let shouldShowAd: Bool
    let onAdShown: (GADAdReward?) -> Void
    let onAdFailed: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: shouldShowAd) { _, newValue in
                if newValue {
                    showRewardedAd()
                }
            }
    }
    
    private func showRewardedAd() {
        guard !showingAd else { return }
        showingAd = true
        
        adManager.showRewardedAd { success, reward in
            showingAd = false
            if success {
                onAdShown(reward)
            } else {
                onAdFailed()
            }
        }
    }
}

extension View {
    /// 보상형 광고를 표시하는 뷰 모디파이어
    func showRewardedAd(
        when shouldShow: Bool,
        onShown: @escaping (GADAdReward?) -> Void = { _ in },
        onFailed: @escaping () -> Void = {}
    ) -> some View {
        modifier(AdMobRewardedModifier(
            shouldShowAd: shouldShow,
            onAdShown: onShown,
            onAdFailed: onFailed
        ))
    }
}

import Foundation
import SwiftUI
import GoogleMobileAds

/// 광고 시청 보상 관리자
@MainActor
class AdRewardManager: ObservableObject {
    static let shared = AdRewardManager()
    
    @Published var totalRewardPoints: Int = 0
    @Published var dailyAdWatchCount: Int = 0
    @Published var lastAdWatchDate: Date?
    
    // 보상 설정
    private let pointsPerAd = 10
    private let maxDailyAds = 5
    private let bonusMultiplier = 2 // 일일 최대 시청시 보너스
    
    private let userDefaults = UserDefaults.standard
    private let rewardPointsKey = "AdRewardPoints"
    private let dailyAdCountKey = "DailyAdCount"
    private let lastAdDateKey = "LastAdWatchDate"
    
    private init() {
        loadRewardData()
    }
    
    /// 보상 데이터 로드
    private func loadRewardData() {
        totalRewardPoints = userDefaults.integer(forKey: rewardPointsKey)
        dailyAdWatchCount = userDefaults.integer(forKey: dailyAdCountKey)
        
        if let dateData = userDefaults.object(forKey: lastAdDateKey) as? Date {
            lastAdWatchDate = dateData
            
            // 날짜가 바뀌었으면 일일 카운트 리셋
            if !Calendar.current.isDate(dateData, inSameDayAs: Date()) {
                resetDailyCount()
            }
        }
    }
    
    /// 보상 데이터 저장
    private func saveRewardData() {
        userDefaults.set(totalRewardPoints, forKey: rewardPointsKey)
        userDefaults.set(dailyAdWatchCount, forKey: dailyAdCountKey)
        userDefaults.set(lastAdWatchDate, forKey: lastAdDateKey)
    }
    
    /// 일일 카운트 리셋
    private func resetDailyCount() {
        dailyAdWatchCount = 0
        saveRewardData()
    }
    
    /// 광고 시청 보상 처리
    func processAdReward(_ reward: GADAdReward) {
        let currentDate = Date()
        
        // 일일 제한 확인
        if dailyAdWatchCount >= maxDailyAds {
            print("Daily ad watch limit reached")
            return
        }
        
        // 보상 포인트 계산
        var rewardPoints = pointsPerAd
        
        // 일일 최대 시청시 보너스
        if dailyAdWatchCount == maxDailyAds - 1 {
            rewardPoints *= bonusMultiplier
        }
        
        // 보상 적용
        totalRewardPoints += rewardPoints
        dailyAdWatchCount += 1
        lastAdWatchDate = currentDate
        
        saveRewardData()
        
        print("Ad reward processed: +\(rewardPoints) points (Total: \(totalRewardPoints))")
    }
    
    /// 보상 포인트로 혜택 구매 (예: 힌트, 추가 시간 등)
    func purchaseBenefit(_ benefit: AdRewardBenefit) -> Bool {
        guard totalRewardPoints >= benefit.cost else {
            return false
        }
        
        totalRewardPoints -= benefit.cost
        saveRewardData()
        
        print("Benefit purchased: \(benefit.name) for \(benefit.cost) points")
        return true
    }
    
    /// 일일 광고 시청 가능 여부
    var canWatchAdToday: Bool {
        return dailyAdWatchCount < maxDailyAds
    }
    
    /// 남은 일일 광고 시청 횟수
    var remainingDailyAds: Int {
        return max(0, maxDailyAds - dailyAdWatchCount)
    }
    
    /// 다음 보너스까지 남은 광고 수
    var adsUntilBonus: Int {
        if dailyAdWatchCount >= maxDailyAds {
            return 0
        }
        return maxDailyAds - dailyAdWatchCount
    }
}

/// 광고 보상으로 구매할 수 있는 혜택
struct AdRewardBenefit {
    let id: String
    let name: String
    let description: String
    let cost: Int
    let icon: String
    
    static let hint = AdRewardBenefit(
        id: "hint",
        name: "힌트",
        description: "현재 문제의 힌트를 확인할 수 있습니다",
        cost: 20,
        icon: "lightbulb"
    )
    
    static let extraTime = AdRewardBenefit(
        id: "extra_time",
        name: "추가 시간",
        description: "퀴즈 시간을 30초 연장합니다",
        cost: 15,
        icon: "clock"
    )
    
    static let skipQuestion = AdRewardBenefit(
        id: "skip_question",
        name: "문제 건너뛰기",
        description: "현재 문제를 건너뛰고 다음 문제로 이동합니다",
        cost: 25,
        icon: "forward"
    )
    
    static let allBenefits: [AdRewardBenefit] = [
        .hint, .extraTime, .skipQuestion
    ]
}

/// 광고 보상 상태를 표시하는 SwiftUI 뷰
struct AdRewardStatusView: View {
    @StateObject private var rewardManager = AdRewardManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // 총 포인트
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(rewardManager.totalRewardPoints)")
                    .font(.brainyBody)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // 일일 광고 시청 현황
            if rewardManager.canWatchAdToday {
                HStack(spacing: 4) {
                    Image(systemName: "play.rectangle")
                        .foregroundColor(.brainyAccent)
                    Text("\(rewardManager.remainingDailyAds)회 남음")
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("일일 완료")
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.brainyCardBackground)
        .cornerRadius(12)
    }
}

/// 보상형 광고 버튼
struct RewardedAdButton: View {
    @StateObject private var adManager = AdMobManager.shared
    @StateObject private var rewardManager = AdRewardManager.shared
    @State private var shouldShowAd = false
    
    let title: String
    let onRewardEarned: () -> Void
    
    var body: some View {
        BrainyButton(title, style: .secondary) {
            if rewardManager.canWatchAdToday {
                shouldShowAd = true
            }
        }
        .disabled(!rewardManager.canWatchAdToday || !adManager.isRewardedAdAvailable)
        .showRewardedAd(when: shouldShowAd) { reward in
            shouldShowAd = false
            if let reward = reward {
                rewardManager.processAdReward(reward)
                onRewardEarned()
            }
        } onFailed: {
            shouldShowAd = false
        }
    }
}

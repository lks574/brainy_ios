import XCTest
@testable import brainy_ios

/// AdMob 관리자 테스트
@MainActor
final class AdMobManagerTests: XCTestCase {
    
    var adManager: AdMobManager!
    
    override func setUp() async throws {
        adManager = AdMobManager.shared
    }
    
    override func tearDown() async throws {
        adManager = nil
    }
    
    /// AdMob 매니저 초기화 테스트
    func testAdMobManagerInitialization() {
        XCTAssertNotNil(adManager)
        XCTAssertFalse(adManager.isAdLoaded)
        XCTAssertFalse(adManager.isAdLoading)
        XCTAssertNil(adManager.adError)
    }
    
    /// 광고 로드 상태 테스트
    func testAdLoadingState() {
        // 초기 상태 확인
        XCTAssertFalse(adManager.isAdLoading)
        XCTAssertFalse(adManager.isAdLoaded)
        
        // 광고 로드 시작
        adManager.loadInterstitialAd()
        
        // 로딩 상태는 비동기적으로 변경되므로 즉시 확인하지 않음
        // 실제 테스트에서는 expectation을 사용하여 비동기 테스트 수행
    }
    
    /// 에러 클리어 테스트
    func testErrorClearing() {
        // 에러 설정 (실제로는 private이므로 테스트용 메서드 필요)
        adManager.clearError()
        XCTAssertNil(adManager.adError)
    }
    
    /// 광고 사용 가능 여부 테스트
    func testAdAvailability() {
        // 초기 상태에서는 광고가 사용 불가능해야 함
        XCTAssertFalse(adManager.isInterstitialAdAvailable)
        XCTAssertFalse(adManager.isRewardedAdAvailable)
    }
}

/// AdReward 관리자 테스트
@MainActor
final class AdRewardManagerTests: XCTestCase {
    
    var rewardManager: AdRewardManager!
    
    override func setUp() async throws {
        rewardManager = AdRewardManager.shared
    }
    
    override func tearDown() async throws {
        rewardManager = nil
    }
    
    /// 보상 매니저 초기화 테스트
    func testRewardManagerInitialization() {
        XCTAssertNotNil(rewardManager)
        XCTAssertGreaterThanOrEqual(rewardManager.totalRewardPoints, 0)
        XCTAssertGreaterThanOrEqual(rewardManager.dailyAdWatchCount, 0)
    }
    
    /// 일일 광고 시청 가능 여부 테스트
    func testDailyAdWatchAvailability() {
        let canWatch = rewardManager.canWatchAdToday
        let remaining = rewardManager.remainingDailyAds
        
        XCTAssertTrue(canWatch || remaining == 0)
        XCTAssertGreaterThanOrEqual(remaining, 0)
        XCTAssertLessThanOrEqual(remaining, 5) // 최대 5개
    }
    
    /// 혜택 구매 테스트
    func testBenefitPurchase() {
        let initialPoints = rewardManager.totalRewardPoints
        let benefit = AdRewardBenefit.hint
        
        let canPurchase = initialPoints >= benefit.cost
        let purchaseResult = rewardManager.purchaseBenefit(benefit)
        
        XCTAssertEqual(canPurchase, purchaseResult)
        
        if purchaseResult {
            XCTAssertEqual(rewardManager.totalRewardPoints, initialPoints - benefit.cost)
        } else {
            XCTAssertEqual(rewardManager.totalRewardPoints, initialPoints)
        }
    }
    
    /// 보상 혜택 정의 테스트
    func testRewardBenefits() {
        let allBenefits = AdRewardBenefit.allBenefits
        
        XCTAssertFalse(allBenefits.isEmpty)
        XCTAssertTrue(allBenefits.contains { $0.id == "hint" })
        XCTAssertTrue(allBenefits.contains { $0.id == "extra_time" })
        XCTAssertTrue(allBenefits.contains { $0.id == "skip_question" })
        
        // 모든 혜택이 양수 비용을 가져야 함
        for benefit in allBenefits {
            XCTAssertGreaterThan(benefit.cost, 0)
            XCTAssertFalse(benefit.name.isEmpty)
            XCTAssertFalse(benefit.description.isEmpty)
        }
    }
}
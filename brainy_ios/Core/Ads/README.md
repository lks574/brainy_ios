# AdMob 광고 통합 가이드

## 개요

Brainy 앱에서 AdMob 광고 시스템을 통합하여 수익화를 구현합니다. 전면 광고와 보상형 광고를 지원하며, 광고 시청 보상 시스템을 포함합니다.

## 구성 요소

### 1. AdMobManager
- 전면 광고(Interstitial Ad) 및 보상형 광고(Rewarded Ad) 관리
- 광고 로드, 표시, 에러 처리
- SwiftUI 통합을 위한 View Modifier 제공

### 2. AdRewardManager
- 광고 시청 보상 시스템 관리
- 일일 광고 시청 제한 및 포인트 시스템
- 보상으로 구매할 수 있는 혜택 관리

## 사용법

### 전면 광고 표시

```swift
struct MyView: View {
    @State private var shouldShowAd = false
    
    var body: some View {
        VStack {
            Button("Show Ad") {
                shouldShowAd = true
            }
        }
        .showInterstitialAd(when: shouldShowAd) {
            // 광고 표시 성공
            shouldShowAd = false
        } onFailed: {
            // 광고 표시 실패
            shouldShowAd = false
        }
    }
}
```

### 보상형 광고 표시

```swift
struct MyView: View {
    var body: some View {
        RewardedAdButton(title: "보상 받기") {
            // 보상 획득 후 실행할 코드
            print("Reward earned!")
        }
    }
}
```

### 보상 상태 표시

```swift
struct MyView: View {
    var body: some View {
        VStack {
            AdRewardStatusView()
            // 다른 컨텐츠
        }
    }
}
```

## 설정

### 1. Info.plist 설정
- `NSUserTrackingUsageDescription`: 사용자 추적 권한 설명
- `SKAdNetworkItems`: SKAdNetwork 식별자 목록

### 2. Ad Unit ID 설정
현재 테스트 Ad Unit ID를 사용 중입니다. 실제 배포 시에는 AdMobManager.swift에서 실제 Ad Unit ID로 변경해야 합니다.

```swift
// 테스트 ID (현재)
private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"

// 실제 배포용 ID로 변경 필요
private let interstitialAdUnitID = "ca-app-pub-YOUR_PUBLISHER_ID/YOUR_AD_UNIT_ID"
private let rewardedAdUnitID = "ca-app-pub-YOUR_PUBLISHER_ID/YOUR_REWARDED_AD_UNIT_ID"
```

## 광고 표시 시점

### 1. 퀴즈 완료 후
- QuizResultView에서 자동으로 전면 광고 표시
- 광고 로드 실패 시에도 정상 진행

### 2. 보상형 광고
- 힌트, 추가 시간, 문제 건너뛰기 등의 혜택 제공
- 일일 시청 제한 (최대 5회)
- 포인트 시스템으로 혜택 구매

## 에러 처리

### 광고 로드 실패
- 네트워크 연결 문제
- Ad Unit ID 오류
- 광고 인벤토리 부족

### 광고 표시 실패
- 앱이 백그라운드 상태
- 다른 전체 화면 컨텐츠 표시 중
- 광고가 만료됨

모든 에러 상황에서 앱의 정상 기능은 계속 동작합니다.

## 테스트

### 단위 테스트
- AdMobManagerTests: 광고 관리자 기능 테스트
- AdRewardManagerTests: 보상 시스템 테스트

### 통합 테스트
- 실제 디바이스에서 테스트 광고 표시 확인
- 보상 시스템 동작 확인

## 주의사항

1. **테스트 광고 사용**: 개발 중에는 반드시 테스트 Ad Unit ID 사용
2. **실제 광고 클릭 금지**: 개발자가 실제 광고를 클릭하면 계정 정지 위험
3. **광고 정책 준수**: Google AdMob 정책을 준수하여 구현
4. **사용자 경험**: 광고가 사용자 경험을 해치지 않도록 적절한 타이밍에 표시

## 배포 전 체크리스트

- [ ] 실제 Ad Unit ID로 변경
- [ ] 테스트 디바이스에서 광고 표시 확인
- [ ] App Store 심사 가이드라인 준수 확인
- [ ] 광고 정책 준수 확인
- [ ] 사용자 추적 권한 요청 구현 (iOS 14.5+)
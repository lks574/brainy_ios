import SwiftUI

/// 로컬 우선 동기화 화면
struct LocalFirstSyncView: View {
    @ObservedObject var viewModel: SyncViewModel
    let userId: String
    
    var body: some View {
        VStack(spacing: 24) {
            // 동기화 상태 카드
            syncStatusCard
            
            // 대기 중인 항목 카드
            if viewModel.pendingSyncCount > 0 {
                pendingItemsCard
            }
            
            // 리더보드 캐시 카드
            leaderboardCacheCard
            
            // 수동 동기화 버튼
            manualSyncButton
            
            // 오프라인 모드 안내
            if viewModel.isOfflineMode {
                offlineModeNotice
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationTitle("데이터 동기화")
        .navigationBarTitleDisplayMode(.large)
        .alert("동기화 알림", isPresented: $viewModel.showingSyncAlert) {
            Button("확인") {
                viewModel.clearSyncMessage()
            }
        } message: {
            Text(viewModel.syncMessage)
        }
        .task {
            await viewModel.refreshStatus()
        }
    }
    
    // MARK: - Sync Status Card
    
    private var syncStatusCard: some View {
        BrainyCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: viewModel.syncStatusIcon)
                        .foregroundColor(viewModel.syncStatusColor)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("동기화 상태")
                            .font(.brainyHeadline)
                            .foregroundColor(.brainyText)
                        
                        Text(viewModel.syncStatusMessage)
                            .font(.brainyBody)
                            .foregroundColor(.brainyTextSecondary)
                    }
                    
                    Spacer()
                }
                
                // 동기화 진행률 표시
                if case .syncing(let progress) = viewModel.syncStatus {
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(.brainyPrimary)
                        
                        Text("\(Int(progress * 100))% 완료")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                    }
                }
                
                // 마지막 동기화 시간
                if let lastSyncTime = viewModel.lastSyncTime {
                    HStack {
                        Text("마지막 동기화:")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                        
                        Spacer()
                        
                        Text(viewModel.lastSyncTimeString)
                            .font(.brainyCaption)
                            .foregroundColor(.brainyText)
                    }
                }
            }
        }
    }
    
    // MARK: - Pending Items Card
    
    private var pendingItemsCard: some View {
        BrainyCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundColor(.brainySecondary)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("동기화 대기 중")
                            .font(.brainyHeadline)
                            .foregroundColor(.brainyText)
                        
                        Text("\(viewModel.pendingSyncCount)개 항목이 동기화를 기다리고 있습니다")
                            .font(.brainyBody)
                            .foregroundColor(.brainyTextSecondary)
                    }
                    
                    Spacer()
                }
                
                Text("퀴즈 결과는 로컬에 저장되며, 동기화 버튼을 눌러 서버에 업로드할 수 있습니다.")
                    .font(.brainyCaption)
                    .foregroundColor(.brainyTextSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    // MARK: - Leaderboard Cache Card
    
    private var leaderboardCacheCard: some View {
        BrainyCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trophy")
                        .foregroundColor(.brainyAccent)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("리더보드")
                            .font(.brainyHeadline)
                            .foregroundColor(.brainyText)
                        
                        if let cacheAge = viewModel.leaderboardCacheAgeString {
                            Text("마지막 업데이트: \(cacheAge)")
                                .font(.brainyBody)
                                .foregroundColor(.brainyTextSecondary)
                        } else {
                            Text("아직 업데이트되지 않음")
                                .font(.brainyBody)
                                .foregroundColor(.brainyTextSecondary)
                        }
                    }
                    
                    Spacer()
                }
                
                if !viewModel.canSyncLeaderboard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("리더보드는 하루에 한 번만 업데이트됩니다.")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                        
                        if let nextSyncTime = viewModel.nextLeaderboardSyncString {
                            Text("다음 업데이트: \(nextSyncTime)")
                                .font(.brainyCaption)
                                .foregroundColor(.brainyText)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Manual Sync Button
    
    private var manualSyncButton: some View {
        BrainyButton(
            viewModel.syncStatus.isInProgress ? "동기화 중..." : "수동 동기화",
            style: .primary,
            isEnabled: viewModel.isSyncButtonEnabled
        ) {
            Task {
                await viewModel.performManualSync(for: userId)
            }
        }
        .disabled(!viewModel.isSyncButtonEnabled)
    }
    
    // MARK: - Offline Mode Notice
    
    private var offlineModeNotice: some View {
        BrainyCard {
            HStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.brainySecondary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("오프라인 모드")
                        .font(.brainyHeadline)
                        .foregroundColor(.brainyText)
                    
                    Text("네트워크에 연결되지 않았습니다. 모든 데이터는 로컬에 저장되며, 연결 시 동기화할 수 있습니다.")
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LocalFirstSyncView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LocalFirstSyncView(
                viewModel: SyncViewModel(
                    localFirstSyncManager: LocalFirstSyncManager(
                        localDataManager: LocalDataManager(modelContext: ModelContext()),
                        networkService: MockNetworkService()
                    ),
                    localDataManager: LocalDataManager(modelContext: ModelContext())
                ),
                userId: "preview_user"
            )
        }
    }
}
#endif
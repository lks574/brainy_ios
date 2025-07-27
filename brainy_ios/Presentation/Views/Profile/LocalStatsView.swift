import SwiftUI

/// 로컬 통계 표시 화면
struct LocalStatsView: View {
    @State private var userStats: UserStats?
    @State private var isLoading = true
    
    let userId: String
    let localDataManager: LocalDataManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    loadingView
                } else if let stats = userStats {
                    statsContent(stats)
                } else {
                    emptyStateView
                }
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("내 통계")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadStats()
        }
        .refreshable {
            await loadStats()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.brainyPrimary)
            
            Text("통계를 계산하고 있습니다...")
                .font(.brainyBody)
                .foregroundColor(.brainyTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Stats Content
    
    private func statsContent(_ stats: UserStats) -> some View {
        VStack(spacing: 20) {
            // 전체 통계 카드
            overallStatsCard(stats)
            
            // 카테고리별 통계
            if !stats.categoryStats.isEmpty {
                categoryStatsSection(stats.categoryStats)
            }
            
            // 활동 통계
            activityStatsCard(stats)
        }
    }
    
    // MARK: - Overall Stats Card
    
    private func overallStatsCard(_ stats: UserStats) -> some View {
        BrainyCard {
            VStack(spacing: 16) {
                Text("전체 통계")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatItem(
                        title: "총 퀴즈",
                        value: "\(stats.totalQuizzes)",
                        icon: "list.bullet",
                        color: .brainyPrimary
                    )
                    
                    StatItem(
                        title: "정답률",
                        value: "\(Int(stats.averageAccuracy * 100))%",
                        icon: "target",
                        color: .brainySuccess
                    )
                    
                    StatItem(
                        title: "총 문제",
                        value: "\(stats.totalQuestions)",
                        icon: "questionmark.circle",
                        color: .brainySecondary
                    )
                    
                    StatItem(
                        title: "연속 일수",
                        value: "\(stats.streakDays)일",
                        icon: "flame",
                        color: .brainyAccent
                    )
                }
            }
        }
    }
    
    // MARK: - Category Stats Section
    
    private func categoryStatsSection(_ categoryStats: [QuizCategory: CategoryStats]) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("카테고리별 통계")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(QuizCategory.allCases, id: \.self) { category in
                    if let stats = categoryStats[category] {
                        CategoryStatRow(category: category, stats: stats)
                    }
                }
            }
        }
    }
    
    // MARK: - Activity Stats Card
    
    private func activityStatsCard(_ stats: UserStats) -> some View {
        BrainyCard {
            VStack(spacing: 16) {
                Text("활동 통계")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.brainySecondary)
                        
                        Text("총 플레이 시간")
                            .font(.brainyBody)
                            .foregroundColor(.brainyText)
                        
                        Spacer()
                        
                        Text(formatTimeInterval(stats.totalTimeSpent))
                            .font(.brainyBody)
                            .foregroundColor(.brainyText)
                            .fontWeight(.medium)
                    }
                    
                    if let lastPlayed = stats.lastPlayedAt {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.brainySecondary)
                            
                            Text("마지막 플레이")
                                .font(.brainyBody)
                                .foregroundColor(.brainyText)
                            
                            Spacer()
                            
                            Text(formatDate(lastPlayed))
                                .font(.brainyBody)
                                .foregroundColor(.brainyText)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.brainySecondary)
                        
                        Text("평균 정답률")
                            .font(.brainyBody)
                            .foregroundColor(.brainyText)
                        
                        Spacer()
                        
                        Text("\(Int(stats.averageAccuracy * 100))%")
                            .font(.brainyBody)
                            .foregroundColor(.brainyText)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.system(size: 60))
                .foregroundColor(.brainyTextSecondary)
            
            Text("아직 통계가 없습니다")
                .font(.brainyHeadline)
                .foregroundColor(.brainyText)
            
            Text("퀴즈를 풀면 통계가 표시됩니다")
                .font(.brainyBody)
                .foregroundColor(.brainyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Private Methods
    
    private func loadStats() async {
        isLoading = true
        
        do {
            let stats = try await localDataManager.calculateLocalStats(for: userId)
            await MainActor.run {
                self.userStats = stats
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.userStats = nil
                self.isLoading = false
            }
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "오늘"
        } else if calendar.isDateInYesterday(date) {
            return "어제"
        } else {
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
                .fontWeight(.bold)
            
            Text(title)
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.brainySurface)
        .cornerRadius(12)
    }
}

// MARK: - Category Stat Row Component

struct CategoryStatRow: View {
    let category: QuizCategory
    let stats: CategoryStats
    
    var body: some View {
        BrainyCard {
            HStack(spacing: 12) {
                // 카테고리 아이콘
                Image(systemName: categoryIcon(for: category))
                    .font(.title3)
                    .foregroundColor(.brainyPrimary)
                    .frame(width: 24)
                
                // 카테고리 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.brainyBody)
                        .foregroundColor(.brainyText)
                        .fontWeight(.medium)
                    
                    Text("\(stats.totalQuizzes)개 퀴즈")
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
                
                Spacer()
                
                // 정확도
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(stats.accuracy * 100))%")
                        .font(.brainyBody)
                        .foregroundColor(.brainyText)
                        .fontWeight(.medium)
                    
                    Text("정답률")
                        .font(.brainyCaption)
                        .foregroundColor(.brainyTextSecondary)
                }
            }
        }
    }
    
    private func categoryIcon(for category: QuizCategory) -> String {
        switch category {
        case .person:
            return "person.circle"
        case .general:
            return "lightbulb"
        case .country:
            return "globe"
        case .drama:
            return "tv"
        case .music:
            return "music.note"
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LocalStatsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LocalStatsView(
                userId: "preview_user",
                localDataManager: LocalDataManager(modelContext: ModelContext())
            )
        }
    }
}
#endif
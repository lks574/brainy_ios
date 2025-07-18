import SwiftUI

/// 히스토리 화면
struct HistoryView: View {
    @State private var coordinator: AppCoordinator
    @State private var viewModel: HistoryViewModel
    @State private var showingFilters = false
    
    init(coordinator: AppCoordinator) {
        self._coordinator = State(initialValue: coordinator)
        
        // ViewModel 초기화 (실제로는 DI를 통해 주입받아야 함)
        let quizRepository = QuizDataFactory.shared.createQuizRepository()
        self._viewModel = State(initialValue: HistoryViewModel(quizRepository: quizRepository))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.quizSessions.isEmpty {
                emptyStateView
            } else {
                historyContentView
            }
        }
        .background(Color.brainyBackground)
        .navigationBarHidden(true)
        .task {
            await viewModel.loadHistory()
        }
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingFilters) {
            filtersView
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    coordinator.navigateBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.brainyText)
                }
                
                Spacer()
                
                Text("퀴즈 히스토리")
                    .font(.brainyTitle)
                    .foregroundColor(.brainyText)
                
                Spacer()
                
                Button(action: {
                    showingFilters = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.brainyText)
                }
            }
            
            // Statistics Summary
            if !viewModel.quizSessions.isEmpty {
                statisticsSummaryView
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Statistics Summary
    
    private var statisticsSummaryView: some View {
        HStack(spacing: 16) {
            StatisticCard(
                title: "총 퀴즈",
                value: "\(viewModel.totalQuizzes)개",
                icon: "doc.text"
            )
            
            StatisticCard(
                title: "평균 점수",
                value: String(format: "%.1f%%", viewModel.averageScore * 100),
                icon: "chart.line.uptrend.xyaxis"
            )
            
            StatisticCard(
                title: "총 시간",
                value: formatTotalTime(viewModel.totalTimeSpent),
                icon: "clock"
            )
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("히스토리를 불러오는 중...")
                .font(.brainyBody)
                .foregroundColor(.brainyTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.brainyTextSecondary)
            
            VStack(spacing: 8) {
                Text("아직 풀어본 퀴즈가 없어요")
                    .font(.brainyHeadline)
                    .foregroundColor(.brainyText)
                
                Text("첫 번째 퀴즈를 시작해보세요!")
                    .font(.brainyBody)
                    .foregroundColor(.brainyTextSecondary)
            }
            
            BrainyButton("퀴즈 시작하기", style: .primary) {
                coordinator.navigateBack()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
    
    // MARK: - History Content View
    
    private var historyContentView: some View {
        VStack(spacing: 0) {
            // Filter indicator
            if viewModel.selectedCategory != nil || viewModel.selectedMode != nil {
                filterIndicatorView
            }
            
            // History list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredSessions, id: \.id) { session in
                        HistorySessionCard(session: session) {
                            viewModel.selectSession(session)
                            coordinator.navigateToHistoryDetail(session: session)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - Filter Indicator
    
    private var filterIndicatorView: some View {
        HStack {
            Text("필터 적용됨:")
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
            
            if let category = viewModel.selectedCategory {
                FilterChip(text: category.rawValue) {
                    viewModel.setCategory(nil)
                }
            }
            
            if let mode = viewModel.selectedMode {
                FilterChip(text: mode.rawValue) {
                    viewModel.setMode(nil)
                }
            }
            
            Spacer()
            
            Button("전체 보기") {
                viewModel.clearFilters()
            }
            .font(.brainyCaption)
            .foregroundColor(.brainyAccent)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(Color.brainySurface)
    }
    
    // MARK: - Filters View
    
    private var filtersView: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Category Filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("카테고리")
                        .font(.brainyHeadline)
                        .foregroundColor(.brainyText)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(QuizCategory.allCases, id: \.self) { category in
                            FilterButton(
                                text: category.rawValue,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.setCategory(viewModel.selectedCategory == category ? nil : category)
                            }
                        }
                    }
                }
                
                // Mode Filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("모드")
                        .font(.brainyHeadline)
                        .foregroundColor(.brainyText)
                    
                    HStack(spacing: 8) {
                        ForEach(QuizMode.allCases, id: \.self) { mode in
                            FilterButton(
                                text: mode.rawValue,
                                isSelected: viewModel.selectedMode == mode
                            ) {
                                viewModel.setMode(viewModel.selectedMode == mode ? nil : mode)
                            }
                        }
                        Spacer()
                    }
                }
                
                // Sort Order
                VStack(alignment: .leading, spacing: 12) {
                    Text("정렬")
                        .font(.brainyHeadline)
                        .foregroundColor(.brainyText)
                    
                    VStack(spacing: 8) {
                        ForEach(HistorySortOrder.allCases, id: \.self) { order in
                            FilterButton(
                                text: order.rawValue,
                                isSelected: viewModel.sortOrder == order,
                                style: .fullWidth
                            ) {
                                viewModel.setSortOrder(order)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("초기화") {
                    viewModel.clearFilters()
                },
                trailing: Button("완료") {
                    showingFilters = false
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTotalTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - Supporting Views

/// 통계 카드
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.brainyAccent)
            
            Text(value)
                .font(.brainyHeadline)
                .foregroundColor(.brainyText)
            
            Text(title)
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.brainyCardBackground)
        .cornerRadius(12)
    }
}

/// 히스토리 세션 카드
struct HistorySessionCard: View {
    let session: QuizSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            BrainyCard {
                VStack(spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.category.rawValue)
                                .font(.brainyHeadline)
                                .foregroundColor(.brainyText)
                            
                            Text(session.displayDate)
                                .font(.brainyCaption)
                                .foregroundColor(.brainyTextSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(session.displayScore)
                                .font(.brainyHeadline)
                                .foregroundColor(.brainyText)
                            
                            Text(session.displayAccuracy)
                                .font(.brainyCaption)
                                .foregroundColor(session.accuracyRate >= 0.8 ? .brainySuccess : .brainyTextSecondary)
                        }
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.brainySurface)
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(Color.brainyAccent)
                                .frame(width: geometry.size.width * session.accuracyRate, height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(height: 4)
                    
                    // Footer
                    HStack {
                        Label(session.mode.rawValue, systemImage: "gamecontroller")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                        
                        Spacer()
                        
                        Label(session.displayDuration, systemImage: "clock")
                            .font(.brainyCaption)
                            .foregroundColor(.brainyTextSecondary)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 필터 칩
struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.brainyCaption)
                .foregroundColor(.brainyText)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.brainyTextSecondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.brainyCardBackground)
        .cornerRadius(12)
    }
}

/// 필터 버튼
struct FilterButton: View {
    let text: String
    let isSelected: Bool
    var style: FilterButtonStyle = .normal
    let onTap: () -> Void
    
    enum FilterButtonStyle {
        case normal
        case fullWidth
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.brainyBody)
                .foregroundColor(isSelected ? .white : .brainyText)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: style == .fullWidth ? .infinity : nil)
                .background(isSelected ? Color.brainyAccent : Color.brainyCardBackground)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

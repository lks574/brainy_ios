import Foundation
import SwiftData
import UIKit

/// 데이터 동기화를 관리하는 Actor 클래스
actor SyncManager {
    private let networkService: NetworkServiceProtocol
    private let localDataSource: LocalDataSource
    private var syncInProgress = false
    
    init(networkService: NetworkServiceProtocol, localDataSource: LocalDataSource) {
        self.networkService = networkService
        self.localDataSource = localDataSource
    }
    
    // MARK: - Public Methods
    
    /// 사용자 진행 데이터를 서버에 동기화합니다
    func syncUserProgress(userId: String) async throws {
        guard !syncInProgress else {
            throw BrainyError.syncFailed("동기화가 이미 진행 중입니다")
        }
        
        syncInProgress = true
        defer { syncInProgress = false }
        
        do {
            // 1. 로컬 데이터 수집
            let syncData = try await collectLocalData(userId: userId)
            
            // 2. 서버로 데이터 전송
            let response: SyncResponse = try await networkService.request(
                SyncAPIEndpoint.uploadUserData(data: syncData)
            )
            
            // 3. 서버에서 받은 데이터로 로컬 업데이트
            try await updateLocalData(from: response, userId: userId)
            
            // 4. 마지막 동기화 시간 업데이트
            try await updateLastSyncTime(userId: userId)
            
        } catch {
            throw BrainyError.syncFailed("동기화 실패: \(error.localizedDescription)")
        }
    }
    
    /// 서버에서 사용자 데이터를 복원합니다
    func restoreUserData(userId: String) async throws {
        guard !syncInProgress else {
            throw BrainyError.syncFailed("동기화가 이미 진행 중입니다")
        }
        
        syncInProgress = true
        defer { syncInProgress = false }
        
        do {
            // 서버에서 사용자 데이터 다운로드
            let userData: UserBackupData = try await networkService.request(
                SyncAPIEndpoint.downloadUserData(userId: userId)
            )
            
            // 로컬 데이터 복원
            try await restoreLocalData(from: userData, userId: userId)
            
            // 마지막 동기화 시간 업데이트
            try await updateLastSyncTime(userId: userId)
            
        } catch {
            throw BrainyError.syncFailed("데이터 복원 실패: \(error.localizedDescription)")
        }
    }
    
    /// 동기화 상태를 확인합니다
    func getSyncStatus(userId: String) async throws -> SyncStatus {
        do {
            let status: SyncStatus = try await networkService.request(
                SyncAPIEndpoint.getSyncStatus(userId: userId)
            )
            return status
        } catch {
            // 네트워크 오류 시 로컬 상태 반환
            let user = try await MainActor.run {
                try localDataSource.fetchUser(byId: userId)
            }
            return SyncStatus(
                userId: userId,
                lastSyncAt: user?.lastSyncAt,
                isUpToDate: false,
                pendingChanges: 0
            )
        }
    }
    
    /// 동기화가 진행 중인지 확인합니다
    func isSyncInProgress() -> Bool {
        return syncInProgress
    }
    
    // MARK: - Private Methods
    
    /// 로컬 데이터를 수집합니다
    private func collectLocalData(userId: String) async throws -> UserSyncData {
        let quizResults = try await MainActor.run {
            try localDataSource.fetchQuizResults(by: userId)
        }
        
        let quizSessions = try await MainActor.run {
            try localDataSource.fetchQuizSessions(by: userId)
        }
        
        let user = try await MainActor.run {
            try localDataSource.fetchUser(byId: userId)
        }
        
        return UserSyncData(
            userId: userId,
            quizResults: quizResults.map { SyncQuizResult(from: $0) },
            quizSessions: quizSessions.map { SyncQuizSession(from: $0) },
            lastSyncAt: user?.lastSyncAt ?? Date(),
            deviceInfo: await DeviceInfo.current()
        )
    }
    
    /// 서버 응답으로 로컬 데이터를 업데이트합니다
    private func updateLocalData(from response: SyncResponse, userId: String) async throws {
        try await MainActor.run {
            // 서버에서 받은 새로운 결과들을 로컬에 저장
            for syncResult in response.newResults {
                let quizResult = QuizResult(
                    id: syncResult.id,
                    userId: syncResult.userId,
                    questionId: syncResult.questionId,
                    userAnswer: syncResult.userAnswer,
                    isCorrect: syncResult.isCorrect,
                    timeSpent: syncResult.timeSpent,
                    category: syncResult.category,
                    quizMode: syncResult.quizMode
                )
                quizResult.completedAt = syncResult.completedAt
                try localDataSource.saveQuizResult(quizResult)
            }
            
            // 서버에서 받은 새로운 세션들을 로컬에 저장
            for syncSession in response.newSessions {
                let quizSession = QuizSession(
                    id: syncSession.id,
                    userId: syncSession.userId,
                    category: syncSession.category,
                    mode: syncSession.mode,
                    totalQuestions: syncSession.totalQuestions
                )
                quizSession.correctAnswers = syncSession.correctAnswers
                quizSession.totalTime = syncSession.totalTime
                quizSession.startedAt = syncSession.startedAt
                quizSession.completedAt = syncSession.completedAt
                try localDataSource.saveQuizSession(quizSession)
            }
        }
    }
    
    /// 서버 백업 데이터로 로컬 데이터를 복원합니다
    private func restoreLocalData(from backupData: UserBackupData, userId: String) async throws {
        try await MainActor.run {
            // 기존 사용자 데이터 삭제
            let existingResults = try localDataSource.fetchQuizResults(by: userId)
            let existingSessions = try localDataSource.fetchQuizSessions(by: userId)
            
            try localDataSource.deleteBatch(existingResults)
            try localDataSource.deleteBatch(existingSessions)
            
            // 백업 데이터 복원
            for syncResult in backupData.quizResults {
                let quizResult = QuizResult(
                    id: syncResult.id,
                    userId: syncResult.userId,
                    questionId: syncResult.questionId,
                    userAnswer: syncResult.userAnswer,
                    isCorrect: syncResult.isCorrect,
                    timeSpent: syncResult.timeSpent,
                    category: syncResult.category,
                    quizMode: syncResult.quizMode
                )
                quizResult.completedAt = syncResult.completedAt
                try localDataSource.saveQuizResult(quizResult)
            }
            
            for syncSession in backupData.quizSessions {
                let quizSession = QuizSession(
                    id: syncSession.id,
                    userId: syncSession.userId,
                    category: syncSession.category,
                    mode: syncSession.mode,
                    totalQuestions: syncSession.totalQuestions
                )
                quizSession.correctAnswers = syncSession.correctAnswers
                quizSession.totalTime = syncSession.totalTime
                quizSession.startedAt = syncSession.startedAt
                quizSession.completedAt = syncSession.completedAt
                try localDataSource.saveQuizSession(quizSession)
            }
        }
    }
    
    /// 마지막 동기화 시간을 업데이트합니다
    private func updateLastSyncTime(userId: String) async throws {
        try await MainActor.run {
            guard let user = try localDataSource.fetchUser(byId: userId) else {
                throw BrainyError.dataError("사용자를 찾을 수 없습니다")
            }
            
            user.lastSyncAt = Date()
            try localDataSource.update()
        }
    }
}


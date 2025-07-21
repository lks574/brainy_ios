import SwiftUI
import AVFoundation
import UIKit

/// 음성 모드 퀴즈 전용 UI 컴포넌트
struct VoiceQuizView: View {
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var speechManager = SpeechRecognitionManager.shared
    @State private var hasRequestedPermissions = false
    @State private var showPermissionAlert = false
    @State private var isPlayingAudio = false
    
    let question: QuizQuestion
    let onAnswerSubmitted: (String) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Audio playback section
            audioPlaybackSection
            
            // Speech recognition section
            speechRecognitionSection
            
            // Answer display section
            answerDisplaySection
        }
        .task {
            await requestPermissionsIfNeeded()
        }
        .alert("권한 필요", isPresented: $showPermissionAlert) {
            Button("설정으로 이동") {
                openAppSettings()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("음성 모드를 사용하려면 마이크와 음성 인식 권한이 필요합니다.")
        }
    }
    
    // MARK: - Audio Playback Section
    private var audioPlaybackSection: some View {
        BrainyCard(style: .quiz, shadow: .medium) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "speaker.wave.2")
                        .font(.title2)
                        .foregroundColor(.brainyPrimary)
                    
                    Text("문제 듣기")
                        .font(.brainyHeadlineSmall)
                        .foregroundColor(.brainyText)
                    
                    Spacer()
                }
                
                // Play button and progress
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await toggleAudioPlayback()
                        }
                    }) {
                        Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.brainyPrimary)
                    }
                    .disabled(isPlayingAudio && !audioManager.isPlaying)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Progress bar
                        ProgressView(value: audioManager.playbackProgress)
                            .tint(.brainyPrimary)
                        
                        // Time display
                        HStack {
                            Text("00:00")
                                .font(.brainyLabelSmall)
                                .foregroundColor(.brainyTextSecondary)
                            
                            Spacer()
                            
                            Text("00:00")
                                .font(.brainyLabelSmall)
                                .foregroundColor(.brainyTextSecondary)
                        }
                    }
                }
                
                // Fallback text question (if audio fails)
                if !isPlayingAudio && !audioManager.isPlaying {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("문제 텍스트")
                            .font(.brainyLabelMedium)
                            .foregroundColor(.brainyTextSecondary)
                        
                        Text(question.question)
                            .font(.brainyBodyLarge)
                            .foregroundColor(.brainyText)
                            .lineLimit(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Speech Recognition Section
    private var speechRecognitionSection: some View {
        BrainyCard(style: .quiz, shadow: .medium) {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "mic")
                        .font(.title2)
                        .foregroundColor(.brainyPrimary)
                    
                    Text("음성으로 답하기")
                        .font(.brainyHeadlineSmall)
                        .foregroundColor(.brainyText)
                    
                    Spacer()
                }
                
                // Recording button and visualization
                VStack(spacing: 16) {
                    // Recording button
                    Button(action: {
                        Task {
                            await toggleSpeechRecognition()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(speechManager.isListening ? Color.red : Color.brainyPrimary)
                                .frame(width: 80, height: 80)
                                .scaleEffect(speechManager.isListening ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), 
                                          value: speechManager.isListening)
                            
                            Image(systemName: speechManager.isListening ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(!speechManager.isAvailable)
                    
                    // Recording status
                    Text(speechManager.isListening ? "듣고 있습니다..." : "탭하여 음성 입력")
                        .font(.brainyBodyMedium)
                        .foregroundColor(speechManager.isListening ? .red : .brainyTextSecondary)
                    
                    // Audio level visualization
                    if speechManager.isListening {
                        AudioLevelVisualization(level: audioManager.recordingLevel)
                    }
                }
            }
        }
    }
    
    // MARK: - Answer Display Section
    private var answerDisplaySection: some View {
        BrainyCard(style: .quiz, shadow: .medium) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "text.bubble")
                        .font(.title2)
                        .foregroundColor(.brainyPrimary)
                    
                    Text("인식된 답안")
                        .font(.brainyHeadlineSmall)
                        .foregroundColor(.brainyText)
                    
                    Spacer()
                    
                    if !speechManager.recognizedText.isEmpty {
                        Button("지우기") {
                            speechManager.clearRecognizedText()
                        }
                        .font(.brainyLabelMedium)
                        .foregroundColor(.brainyPrimary)
                    }
                }
                
                // Recognized text display
                ScrollView {
                    Text(speechManager.recognizedText.isEmpty ? "음성으로 답안을 말해주세요" : speechManager.recognizedText)
                        .font(.brainyBodyLarge)
                        .foregroundColor(speechManager.recognizedText.isEmpty ? .brainyTextSecondary : .brainyText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .frame(minHeight: 60)
                
                // Error message
                if let errorMessage = speechManager.errorMessage {
                    Text(errorMessage)
                        .font(.brainyLabelMedium)
                        .foregroundColor(.brainyError)
                }
                
                // Submit button
                BrainyButton(
                    "답안 제출",
                    style: .primary,
                    size: .medium,
                    isEnabled: !speechManager.recognizedText.isEmpty
                ) {
                    onAnswerSubmitted(speechManager.recognizedText)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func requestPermissionsIfNeeded() async {
        guard !hasRequestedPermissions else { return }
        hasRequestedPermissions = true
        
        let granted = await speechManager.requestPermissions()
        if !granted {
            showPermissionAlert = true
        }
    }
    
    private func toggleAudioPlayback() async {
        if audioManager.isPlaying {
            audioManager.stopPlayback()
        } else {
            await playQuestionAudio()
        }
    }
    
    private func playQuestionAudio() async {
        guard let audioURLString = question.audioURL,
              !audioURLString.isEmpty else {
            return
        }
        
        isPlayingAudio = true
        
        do {
            // Try to get cached audio first
            if let cachedURL = await AudioCacheManager.shared.getCachedAudioURL(for: audioURLString) {
                try await audioManager.playAudio(from: cachedURL)
            } else {
                // Download and cache audio
                let cachedURL = try await AudioCacheManager.shared.downloadAndCacheAudio(from: audioURLString)
                try await audioManager.playAudio(from: cachedURL)
            }
        } catch {
            print("Failed to play audio: \(error)")
            // Audio playback failed, but continue with text-based question
        }
        
        isPlayingAudio = false
    }
    
    private func toggleSpeechRecognition() async {
        if speechManager.isListening {
            speechManager.stopListening()
        } else {
            do {
                try await speechManager.startListening()
            } catch {
                speechManager.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - Audio Level Visualization
struct AudioLevelVisualization: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(level > Float(index) * 0.1 ? Color.brainyPrimary : Color.brainyTextSecondary.opacity(0.3))
                    .frame(width: 3, height: CGFloat(8 + index * 2))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
}
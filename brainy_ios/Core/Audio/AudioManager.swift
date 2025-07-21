import AVFoundation
import Foundation

/// 음성 재생 및 녹음을 관리하는 매니저
@MainActor
final class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var isPlaying = false
    @Published var isRecording = false
    @Published var recordingLevel: Float = 0.0
    @Published var playbackProgress: Double = 0.0
    
    private var audioPlayer: AVAudioPlayer?
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession
    private var progressTimer: Timer?
    
    override init() {
        self.audioSession = AVAudioSession.sharedInstance()
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopPlayback()
        stopRecording()
        progressTimer?.invalidate()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - Playback Methods
    func playAudio(from url: URL) async throws {
        stopPlayback()
        
        do {
            let data = try Data(contentsOf: url)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            if audioPlayer?.play() == true {
                isPlaying = true
                startProgressTimer()
            }
        } catch {
            throw AudioError.playbackFailed(error.localizedDescription)
        }
    }
    
    func playAudio(from data: Data) async throws {
        stopPlayback()
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            if audioPlayer?.play() == true {
                isPlaying = true
                startProgressTimer()
            }
        } catch {
            throw AudioError.playbackFailed(error.localizedDescription)
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackProgress = 0.0
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func resumePlayback() {
        if audioPlayer?.play() == true {
            isPlaying = true
            startProgressTimer()
        }
    }
    
    // MARK: - Recording Methods
    func startRecording() async throws -> URL {
        await requestMicrophonePermission()
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
            if audioRecorder?.record() == true {
                isRecording = true
                startRecordingLevelMonitoring()
                return audioFilename
            } else {
                throw AudioError.recordingFailed("Failed to start recording")
            }
        } catch {
            throw AudioError.recordingFailed(error.localizedDescription)
        }
    }
    
    func stopRecording() -> URL? {
        guard let recorder = audioRecorder else { return nil }
        
        let url = recorder.url
        recorder.stop()
        audioRecorder = nil
        isRecording = false
        recordingLevel = 0.0
        
        return url
    }
    
    // MARK: - Permission Methods
    private func requestMicrophonePermission() async {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume()
            }
        }
    }
    
    func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
        return audioSession.recordPermission
    }
    
    // MARK: - Private Methods
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePlaybackProgress()
            }
        }
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }
        
        if player.duration > 0 {
            playbackProgress = player.currentTime / player.duration
        }
    }
    
    private func startRecordingLevelMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                
                self.audioRecorder?.updateMeters()
                let level = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                // Convert decibel to 0-1 range
                self.recordingLevel = pow(10, level / 20)
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            playbackProgress = 0.0
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            isPlaying = false
            playbackProgress = 0.0
            progressTimer?.invalidate()
            progressTimer = nil
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioManager: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            isRecording = false
            recordingLevel = 0.0
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            isRecording = false
            recordingLevel = 0.0
        }
    }
}

// MARK: - Audio Errors
enum AudioError: LocalizedError {
    case playbackFailed(String)
    case recordingFailed(String)
    case permissionDenied
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .playbackFailed(let message):
            return "음성 재생 실패: \(message)"
        case .recordingFailed(let message):
            return "음성 녹음 실패: \(message)"
        case .permissionDenied:
            return "마이크 권한이 필요합니다"
        case .fileNotFound:
            return "음성 파일을 찾을 수 없습니다"
        }
    }
}
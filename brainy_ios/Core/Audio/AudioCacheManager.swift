import Foundation

/// 음성 파일 다운로드 및 캐싱을 관리하는 매니저
actor AudioCacheManager {
    static let shared = AudioCacheManager()
    
    private let cacheDirectory: URL
    private let urlSession: URLSession
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    private var downloadTasks: [String: Task<URL, Error>] = [:]
    
    private init() {
        // 캐시 디렉토리 설정
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = documentsPath.appendingPathComponent("AudioCache")
        
        // URLSession 설정
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.urlSession = URLSession(configuration: config)
        
        // 캐시 디렉토리 생성
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Public Methods
    func getCachedAudioURL(for audioURL: String) -> URL? {
        let fileName = generateFileName(from: audioURL)
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    func downloadAndCacheAudio(from urlString: String) async throws -> URL {
        // 이미 캐시된 파일이 있는지 확인
        if let cachedURL = getCachedAudioURL(for: urlString) {
            return cachedURL
        }
        
        // 이미 다운로드 중인 작업이 있는지 확인
        if let existingTask = downloadTasks[urlString] {
            return try await existingTask.value
        }
        
        // 새로운 다운로드 작업 생성
        let downloadTask = Task<URL, Error> {
            try await performDownload(from: urlString)
        }
        
        downloadTasks[urlString] = downloadTask
        
        do {
            let result = try await downloadTask.value
            downloadTasks.removeValue(forKey: urlString)
            return result
        } catch {
            downloadTasks.removeValue(forKey: urlString)
            throw error
        }
    }
    
    func preloadAudioFiles(urls: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for urlString in urls {
                group.addTask {
                    do {
                        _ = try await self.downloadAndCacheAudio(from: urlString)
                    } catch {
                        print("Failed to preload audio: \(urlString), error: \(error)")
                    }
                }
            }
        }
    }
    
    func clearCache() throws {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
        }
        
        createCacheDirectoryIfNeeded()
    }
    
    func getCacheSize() -> Int {
        let fileManager = FileManager.default
        var totalSize = 0
        
        guard let enumerator = fileManager.enumerator(at: cacheDirectory, 
                                                     includingPropertiesForKeys: [.fileSizeKey],
                                                     options: [.skipsHiddenFiles]) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += resourceValues.fileSize ?? 0
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    func cleanupOldFiles() throws {
        let fileManager = FileManager.default
        let currentCacheSize = getCacheSize()
        
        guard currentCacheSize > maxCacheSize else { return }
        
        // 파일들을 수정 날짜 순으로 정렬
        guard let enumerator = fileManager.enumerator(at: cacheDirectory,
                                                     includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                                                     options: [.skipsHiddenFiles]) else {
            return
        }
        
        var files: [(url: URL, date: Date, size: Int)] = []
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                if let date = resourceValues.contentModificationDate,
                   let size = resourceValues.fileSize {
                    files.append((url: fileURL, date: date, size: size))
                }
            } catch {
                continue
            }
        }
        
        // 오래된 파일부터 정렬
        files.sort { $0.date < $1.date }
        
        var deletedSize = 0
        let targetSize = maxCacheSize / 2 // 절반까지 줄이기
        
        for file in files {
            if currentCacheSize - deletedSize <= targetSize {
                break
            }
            
            do {
                try fileManager.removeItem(at: file.url)
                deletedSize += file.size
            } catch {
                print("Failed to delete cached file: \(file.url), error: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    private func createCacheDirectoryIfNeeded() {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, 
                                              withIntermediateDirectories: true, 
                                              attributes: nil)
            } catch {
                print("Failed to create cache directory: \(error)")
            }
        }
    }
    
    private func performDownload(from urlString: String) async throws -> URL {
        guard let url = URL(string: urlString) else {
            throw AudioCacheError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AudioCacheError.downloadFailed
        }
        
        let fileName = generateFileName(from: urlString)
        let localURL = cacheDirectory.appendingPathComponent(fileName)
        
        try data.write(to: localURL)
        
        // 캐시 크기 확인 및 정리
        try cleanupOldFiles()
        
        return localURL
    }
    
    private func generateFileName(from urlString: String) -> String {
        let hash = urlString.hash
        return "audio_\(abs(hash)).m4a"
    }
}

// MARK: - Audio Cache Errors
enum AudioCacheError: LocalizedError {
    case invalidURL
    case downloadFailed
    case cacheWriteFailed
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "잘못된 URL입니다"
        case .downloadFailed:
            return "음성 파일 다운로드에 실패했습니다"
        case .cacheWriteFailed:
            return "캐시 저장에 실패했습니다"
        case .fileNotFound:
            return "음성 파일을 찾을 수 없습니다"
        }
    }
}
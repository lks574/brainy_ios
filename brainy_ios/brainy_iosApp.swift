//
//  brainy_iosApp.swift
//  brainy_ios
//
//  Created by KyungSeok Lee on 7/17/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn
import GoogleMobileAds

@main
struct brainy_iosApp: App {
    
    init() {
        // Firebase 초기화
        FirebaseApp.configure()
        
        // Google Sign-In 설정
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            fatalError("GoogleService-Info.plist 파일을 찾을 수 없거나 CLIENT_ID가 없습니다.")
        }
        
        GoogleSignIn.GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        
        // AdMob 초기화
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            QuizQuestion.self,
            QuizResult.self,
            QuizSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GoogleSignIn.GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

import Foundation
// Firebase Analytics SDK를 추가하면 아래 주석을 해제하세요
// import FirebaseAnalytics

final class FirebaseAnalyticsService: AnalyticsServiceProtocol {
    func logEvent(_ event: AnalyticsEvent) {
        // Firebase Analytics SDK 설치 후 사용
        // Analytics.logEvent(event.name, parameters: event.parameters)

        // 현재는 콘솔 출력
        print("🔥 [Firebase] \(event.name)")
        print("   Parameters: \(event.parameters)")
    }

    func setUserProperty(key: String, value: String) {
        // Firebase Analytics SDK 설치 후 사용
        // Analytics.setUserProperty(value, forName: key)

        // 현재는 콘솔 출력
        print("🔥 [Firebase] UserProperty: \(key) = \(value)")
    }
}

/*
 Firebase 사용 방법:

 1. Firebase 프로젝트 생성 (https://console.firebase.google.com)
 2. GoogleService-Info.plist 다운로드 후 프로젝트에 추가
 3. Package.swift 또는 CocoaPods에 Firebase SDK 추가:

    // Swift Package Manager
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
    ]

 4. AppDelegate에서 초기화:

    import FirebaseCore

    func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
        FirebaseApp.configure()
        ...
    }

 5. 위 주석 해제 후 사용
 */

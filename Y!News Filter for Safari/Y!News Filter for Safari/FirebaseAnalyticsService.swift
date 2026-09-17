import FirebaseAnalytics
import FirebaseCore
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureFirebase()
#if canImport(GoogleMobileAds)
        Task {
            if await AdvertisingConsentService.shared.gatherConsentIfNeeded() {
                AppOpenAdService.shared.prepare()
            }
        }
#endif
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
#if canImport(GoogleMobileAds)
        AppOpenAdService.shared.applicationDidBecomeActive()
#endif
    }

    private func configureFirebase() {
        guard FirebaseApp.app() == nil else { return }
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            print("Firebase Analytics: GoogleService-Info.plistを読み込めませんでした。")
            return
        }

        guard options.bundleID == Bundle.main.bundleIdentifier else {
            print("Firebase Analytics: GoogleService-Info.plistのBundle IDが本体アプリと一致しません。")
            return
        }

        FirebaseApp.configure(options: options)
        AppAnalytics.log("app_initialized")
    }
}

enum AppAnalytics {
    static func log(_ name: String, parameters: [String: Any]? = nil) {
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(name, parameters: parameters)
    }

    static func screen(_ name: String) {
        log(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name,
            AnalyticsParameterScreenClass: name
        ])
    }
}

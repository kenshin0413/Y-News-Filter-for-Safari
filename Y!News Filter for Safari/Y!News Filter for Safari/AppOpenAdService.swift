import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds

@MainActor
final class FullScreenAdState {
    static let shared = FullScreenAdState()

    private(set) var isPresenting = false
    func beginPresentation() {
        isPresenting = true
    }

    func endPresentation() {
        isPresenting = false
    }

    var canPresentAppOpenAd: Bool {
        !isPresenting
    }
}

@MainActor
final class AppOpenAdService: NSObject, FullScreenContentDelegate {
    static let shared = AppOpenAdService()

    private var appOpenAd: AppOpenAd?
    private var loadDate: Date?
    private var isLoading = false
    private var shouldPresentWhenLoaded = false

    private var adUnitID: String {
#if DEBUG
        // Google公式のiOSアプリ起動広告テストID。
        "ca-app-pub-3940256099942544/5575463023"
#else
        // AdMobで作成した本番用アプリ起動広告ユニット。
        "ca-app-pub-2277987033120510/8621051962"
#endif
    }

    func prepare() {
        Task {
            await MobileAds.shared.start()
            await loadAdIfNeeded()
        }
    }

    func applicationDidBecomeActive() {
        guard FullScreenAdState.shared.canPresentAppOpenAd else { return }

        if isAdAvailable {
            presentAd()
        } else {
            shouldPresentWhenLoaded = true
            Task { await loadAdIfNeeded() }
        }
    }

    private var isAdAvailable: Bool {
        guard appOpenAd != nil, let loadDate else { return false }
        return Date().timeIntervalSince(loadDate) < 4 * 60 * 60
    }

    private func loadAdIfNeeded() async {
        guard !isLoading, !isAdAvailable else { return }
        isLoading = true

        do {
            let ad = try await AppOpenAd.load(with: adUnitID, request: Request())
            ad.fullScreenContentDelegate = self
            appOpenAd = ad
            loadDate = Date()
            isLoading = false

            if shouldPresentWhenLoaded,
               UIApplication.shared.applicationState == .active,
               FullScreenAdState.shared.canPresentAppOpenAd {
                presentAd()
            }
        } catch {
            isLoading = false
            shouldPresentWhenLoaded = false
            appOpenAd = nil
            loadDate = nil
            print("App Open Ad: 広告を読み込めませんでした: \(error.localizedDescription)")
        }
    }

    private func presentAd() {
        guard let appOpenAd,
              UIApplication.shared.applicationState == .active,
              FullScreenAdState.shared.canPresentAppOpenAd else { return }

        shouldPresentWhenLoaded = false
        FullScreenAdState.shared.beginPresentation()
        AppAnalytics.log("app_open_ad_presented")
        appOpenAd.present(from: nil)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        clearPresentedAd()
        prepare()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("App Open Ad: 広告を表示できませんでした: \(error.localizedDescription)")
        clearPresentedAd()
        prepare()
    }

    private func clearPresentedAd() {
        appOpenAd = nil
        loadDate = nil
        FullScreenAdState.shared.endPresentation()
    }
}
#endif

import Combine
import Foundation

#if canImport(GoogleMobileAds)
import GoogleMobileAds

@MainActor
final class RewardedAdService: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var rewardedAd: RewardedAd?
    private var rewardHandler: (() -> Void)?
    private var isInitialized = false

    // 開発中に本番広告をタップすると無効なトラフィックと判定される可能性があるため、
    // DebugではGoogle公式テストID、App Store向けのReleaseではAdMobの本番IDを使う。
    private var adUnitID: String {
#if DEBUG
        "ca-app-pub-3940256099942544/1712485313"
#else
        "ca-app-pub-2277987033120510/8692817114"
#endif
    }

    override init() {
        super.init()
    }

    func loadAd() async {
        isLoading = true
        errorMessage = nil
        do {
            let ad = try await RewardedAd.load(with: adUnitID, request: Request())
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
        } catch {
            rewardedAd = nil
            errorMessage = userFacingMessage(for: error)
        }
        isLoading = false
    }

    func showAd(onReward: @escaping () -> Void) {
        guard !isLoading else { return }
        rewardHandler = onReward

        if let rewardedAd {
            present(rewardedAd)
            return
        }

        Task {
            guard await AdvertisingConsentService.shared.gatherConsentIfNeeded() else {
                errorMessage = "広告のプライバシー設定を確認してください。"
                rewardHandler = nil
                return
            }
            if !isInitialized {
                isLoading = true
                await MobileAds.shared.start()
                isInitialized = true
            }
            await loadAd()
            guard let rewardedAd else {
                rewardHandler = nil
                return
            }
            present(rewardedAd)
        }
    }

    private func present(_ rewardedAd: RewardedAd) {
        FullScreenAdState.shared.beginPresentation()
        rewardedAd.present(from: nil) { [weak self] in
            self?.rewardHandler?()
            self?.rewardHandler = nil
        }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        rewardedAd = nil
        FullScreenAdState.shared.endPresentation()
        Task { await loadAd() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
        rewardHandler = nil
        FullScreenAdState.shared.endPresentation()
        errorMessage = userFacingMessage(for: error)
        Task { await loadAd() }
    }

    private func userFacingMessage(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("no ad to show") || message.contains("no fill") {
            return "現在表示できる広告がありません。少し時間をおいて、もう一度お試しください。"
        }
        return "広告を読み込めませんでした。通信環境を確認して、もう一度お試しください。"
    }
}
#else
@MainActor
final class RewardedAdService: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String? = "Google Mobile Ads SDKが未接続です。"
    func showAd(onReward: @escaping () -> Void) {}
}
#endif

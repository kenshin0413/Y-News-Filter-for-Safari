import AppTrackingTransparency
import Combine
import UIKit

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
final class AdvertisingConsentService: ObservableObject {
    static let shared = AdvertisingConsentService()

    @Published private(set) var isFinished = false
    private var hasRequestedThisSession = false

    func gatherConsentIfNeeded() async -> Bool {
        defer { isFinished = true }
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-skip-ad-consent-for-ui-test") {
            return false
        }
#endif
#if canImport(UserMessagingPlatform)
        if !hasRequestedThisSession {
            hasRequestedThisSession = true
            do {
                try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
                try await ConsentForm.loadAndPresentIfRequired(from: nil)
            } catch {
                print("Ad consent: \(error.localizedDescription)")
            }
        }

        guard ConsentInformation.shared.canRequestAds else { return false }
#endif

        if #available(iOS 14, *), ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        return true
    }
}

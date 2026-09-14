import StoreKit
import UIKit

enum AppLinks {
    static let privacy = URL(string: "https://narratopia345readersuite.site/privacy/457")
    static let terms = URL(string: "https://narratopia345readersuite.site/terms/457")

    static func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }

    static func requestReview() {
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap { scene in
                scene as? UIWindowScene
            }
            .first
        guard let windowScene else { return }
        SKStoreReviewController.requestReview(in: windowScene)
    }
}

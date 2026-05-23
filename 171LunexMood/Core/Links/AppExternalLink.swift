import Foundation

enum AppExternalLink: String, CaseIterable {
    case privacyPolicy = "https://luneexmood.com/privacy-policy.html"
    case termsOfUse = "https://luneexmood.com/support.html"

    var url: URL? {
        URL(string: rawValue)
    }

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy"
        case .termsOfUse: return "Terms"
        }
    }

    var iconName: String {
        switch self {
        case .privacyPolicy: return "hand.raised.fill"
        case .termsOfUse: return "doc.text.fill"
        }
    }

}

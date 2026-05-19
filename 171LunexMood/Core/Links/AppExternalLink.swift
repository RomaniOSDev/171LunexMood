import Foundation

enum AppExternalLink: String, CaseIterable {
    case privacyPolicy = "https://lunexmood171.site/privacy/173"
    case termsOfUse = "https://lunexmood171.site/terms/173"

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

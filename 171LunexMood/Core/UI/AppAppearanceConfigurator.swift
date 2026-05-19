import UIKit

enum AppAppearanceConfigurator {
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor(named: "AppTextPrimary", in: .main, compatibleWith: nil) ?? .white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor(named: "AppTextPrimary", in: .main, compatibleWith: nil) ?? .white]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().isTranslucent = true

        UIScrollView.appearance().backgroundColor = .clear
        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
    }
}

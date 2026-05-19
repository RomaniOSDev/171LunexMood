import SwiftUI

enum MainTab: Int, CaseIterable {
    case home
    case play
    case achievements
    case settings

    var title: String {
        switch self {
        case .home: return "Home"
        case .play: return "Play"
        case .achievements: return "Achievements"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .play: return "gamecontroller.fill"
        case .achievements: return "rosette"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView(selectedTab: $selectedTab)
            case .play:
                NavigationStack {
                    PlayTabView()
                }
                .appNavigationStyle()
            case .achievements:
                AchievementsTabView()
            case .settings:
                SettingsTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .elevatedSurface(accent: .appAccent, cornerRadius: 22)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func tabButton(_ tab: MainTab) -> some View {
        let selected = selectedTab == tab
        return Button {
            HapticService.lightTap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .scaleEffect(selected ? 1.06 : 1)
                Text(tab.title)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundColor(selected ? .appTextPrimary : .appTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppGradients.surfaceFill(accent: .appAccent))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.appAccent.opacity(0.4), lineWidth: 1)
                        }
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

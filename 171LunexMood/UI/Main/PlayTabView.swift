import SwiftUI

/// Полный список активностей и уровней — открывается с Home или вкладки Play.
struct PlayTabView: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ScreenHeader(
                        title: "All Activities",
                        subtitle: "Pick a game, difficulty, and level",
                        icon: "gamecontroller.fill"
                    )
                    .padding(.top, 8)

                    SectionHeader(title: "Games")
                    ForEach(ActivityDefinition.all) { activity in
                        NavigationLink(value: activity.id) {
                            ActivityListCell(activity: activity)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticService.lightTap()
                        })
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.bottom, 28)
            }
            .appScrollStyle()
        }
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .navigationDestination(for: String.self) { activityId in
            if let activity = ActivityDefinition.find(id: activityId) {
                LevelSelectionView(activity: activity)
            }
        }
    }
}

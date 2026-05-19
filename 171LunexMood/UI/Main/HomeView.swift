import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameProgressStore
    @Binding var selectedTab: MainTab

    private let widgetColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HomeHeroWidget()

                        LazyVGrid(columns: widgetColumns, spacing: 12) {
                            HomeDailyWidget()
                            HomeStreakWidget()
                        }

                        NavigationLink(value: HomeRoute.play(store.suggestedPlay())) {
                            HomeQuickPlayWidget(suggestion: store.suggestedPlay())
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticService.mediumImpact()
                        })

                        HomeWeeklyWidget(levels: WeeklyChallenge.levelsForCurrentWeek())

                        HomeStatsWidget()

                        HomeAchievementsWidget {
                            HapticService.lightTap()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                selectedTab = .achievements
                            }
                        }

                        HomeActivitiesRow()

                        HomeSeeAllGamesCard()
                    }
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
                .appScrollStyle()
            }
            .navigationBarHidden(true)
            .navigationDestination(for: HomeRoute.self) { route in
                destination(for: route)
            }
            .navigationDestination(for: String.self) { activityId in
                if let activity = ActivityDefinition.find(id: activityId) {
                    LevelSelectionView(activity: activity)
                }
            }
        }
        .onAppear {
            store.refreshDailyGoalIfNeeded()
            store.refreshWeeklyChallengeIfNeeded()
        }
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .allGames:
            PlayTabView()
        case .activity(let id):
            if let activity = ActivityDefinition.find(id: id) {
                LevelSelectionView(activity: activity)
            }
        case .play(let suggestion):
            GameEntryView(
                context: GameSessionContext(
                    activityId: suggestion.activityId,
                    difficulty: suggestion.difficulty,
                    level: suggestion.level,
                    isPractice: false
                )
            )
        }
    }
}

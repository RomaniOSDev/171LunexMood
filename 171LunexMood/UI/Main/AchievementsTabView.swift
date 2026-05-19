import SwiftUI

struct AchievementsTabView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var animateUnlock: Set<String> = []
    @State private var filter: AchievementFilter = .all

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    private var filteredAchievements: [Achievement] {
        switch filter {
        case .all:
            return Achievement.all
        case .unlocked:
            return Achievement.all.filter { $0.isUnlocked(store) }
        case .locked:
            return Achievement.all.filter { !$0.isUnlocked(store) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ScreenHeader(
                            title: "Achievements",
                            subtitle: "\(store.unlockedAchievementCount) of \(Achievement.all.count) unlocked",
                            icon: "rosette"
                        )

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(AchievementFilter.allCases, id: \.self) { chip in
                                    FilterChip(
                                        title: chip.rawValue,
                                        isSelected: filter == chip
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            filter = chip
                                        }
                                    }
                                }
                            }
                        }

                        if filteredAchievements.isEmpty {
                            emptyFilterState
                        } else {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(filteredAchievements) { achievement in
                                    AchievementGridCell(
                                        achievement: achievement,
                                        unlocked: achievement.isUnlocked(store),
                                        animate: animateUnlock.contains(achievement.id)
                                    )
                                    .onAppear {
                                        if achievement.isUnlocked(store),
                                           !animateUnlock.contains(achievement.id) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                animateUnlock.insert(achievement.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppLayout.horizontalPadding)
                    .padding(.bottom, 24)
                }
                .appScrollStyle()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true)
            .appNavigationStyle()
        }
    }

    private var emptyFilterState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundColor(.appTextSecondary)
            Text("No achievements in this filter")
                .font(.subheadline)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

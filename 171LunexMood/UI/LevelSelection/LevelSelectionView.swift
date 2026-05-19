import SwiftUI

struct LevelSelectionView: View {
    let activity: ActivityDefinition
    @EnvironmentObject private var store: GameProgressStore
    @State private var difficulty: Difficulty = .easy
    @State private var isPracticeMode = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ActivityHeroHeader(activity: activity)

                    SectionHeader(title: "Difficulty")
                    DifficultySegmentedControl(selection: $difficulty)

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.appAccent.opacity(0.8))
                        Text(DifficultyHint.text(for: difficulty))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .elevatedInset(accent: .appAccent, cornerRadius: 12)

                    PracticeModeCell(isOn: $isPracticeMode)

                    SectionHeader(
                        title: "Levels",
                        trailing: isPracticeMode ? "Practice" : nil
                    )

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<Difficulty.levelCount, id: \.self) { level in
                            levelCell(level: level)
                        }
                    }
                }
                .padding(AppLayout.horizontalPadding)
                .padding(.bottom, 28)
            }
            .appScrollStyle()
        }
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationStyle()
        .navigationDestination(for: GameSessionContext.self) { context in
            GameEntryView(context: context)
        }
    }

    @ViewBuilder
    private func levelCell(level: Int) -> some View {
        let unlocked = isPracticeMode || store.isLevelUnlocked(
            activityId: activity.id,
            difficulty: difficulty,
            level: level
        )
        let stars = store.stars(activityId: activity.id, difficulty: difficulty, level: level)
        let best = store.bestScore(activityId: activity.id, difficulty: difficulty, level: level)

        let cell = LevelGridCell(
            levelNumber: level + 1,
            stars: stars,
            best: best,
            locked: !unlocked,
            isPractice: isPracticeMode
        )

        if unlocked {
            NavigationLink(
                value: GameSessionContext(
                    activityId: activity.id,
                    difficulty: difficulty,
                    level: level,
                    isPractice: isPracticeMode
                )
            ) {
                cell
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                HapticService.mediumImpact()
            })
        } else {
            cell
        }
    }
}

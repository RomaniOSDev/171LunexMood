import SwiftUI

// MARK: - Widget shell

struct HomeWidget<Content: View>: View {
    let title: String
    let icon: String
    var accent: Color = .appPrimary
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundColor(accent)
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.6)
                    .foregroundColor(.appTextSecondary)
                Spacer()
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .elevatedSurface(accent: accent, cornerRadius: AppLayout.cardRadius)
    }
}

// MARK: - Hero

struct HomeHeroWidget: View {
    @EnvironmentObject private var store: GameProgressStore

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.appTextSecondary)
                    Text("Tower Climber")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                    HStack(spacing: 16) {
                        heroStat(value: "\(store.totalStarsEarned)", label: "STARS ⭐")
                        heroStat(value: "\(store.playStreakDays)d", label: "Streak")
                        heroStat(value: "\(store.levelsClearedCount)", label: "Cleared")
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.2))
                        .frame(width: 72, height: 72)
                    Image(systemName: "arrow.up.to.line.compact")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.appAccent)
                }
            }
            .padding(20)
        }
        .frame(minHeight: 148)
        .elevatedSurface(accent: .appAccent, cornerRadius: 22, kind: .hero)
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundColor(.appTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.appTextSecondary)
        }
    }
}

// MARK: - Compact widgets

struct HomeDailyWidget: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        HomeWidget(title: "Daily", icon: "sun.max.fill", accent: .appAccent) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(store.dailyStarsEarnedToday)/\(GameProgressStore.dailyGoalTarget)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.appTextPrimary)
                GradientProgressBar(progress: store.dailyGoalProgress, height: 8)
                Text(store.isDailyGoalComplete ? "Goal complete!" : "STARS today")
                    .font(.caption2)
                    .foregroundColor(.appTextSecondary)
            }
        }
    }
}

struct HomeStreakWidget: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        HomeWidget(title: "Streak", icon: "flame.fill", accent: .appAccent) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(store.playStreakDays)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.appAccent)
                    Text(store.playStreakDays == 1 ? "day" : "days")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(.appAccent.opacity(0.7))
            }
        }
    }
}

struct HomeQuickPlayWidget: View {
    let suggestion: SuggestedPlay

    var body: some View {
        HStack(spacing: 16) {
            if let activity = suggestion.activity {
                IconBadge(systemName: activity.iconName, size: 56)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Continue Climbing")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.appTextSecondary)
                Text(suggestion.label)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Text("Tap to play")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundColor(.appAccent)
            }
            Spacer()
        }
        .padding(18)
        .elevatedSurface(accent: .appAccent, cornerRadius: AppLayout.cardRadius, kind: .hero)
    }
}

struct HomeWeeklyWidget: View {
    @EnvironmentObject private var store: GameProgressStore
    let levels: [WeeklyChallengeLevel]

    var body: some View {
        HomeWidget(
            title: "Weekly",
            icon: "flag.checkered",
            accent: store.weeklyChallengeCompleted ? .appAccent : .appPrimary
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(store.weeklyChallengeCompleted ? "Challenge complete" : "3 levels this week")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.appTextPrimary)
                    Spacer()
                    if store.weeklyChallengeCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.appAccent)
                    }
                }
                ForEach(levels.prefix(2)) { item in
                    Text(item.label)
                        .font(.caption2)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
                if levels.count > 2 {
                    Text("+\(levels.count - 2) more in Play tab")
                        .font(.caption2)
                        .foregroundColor(.appAccent)
                }
            }
        }
    }
}

struct HomeStatsWidget: View {
    @EnvironmentObject private var store: GameProgressStore

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        HomeWidget(title: "Stats", icon: "chart.bar.fill") {
            LazyVGrid(columns: columns, spacing: 10) {
                miniStat(icon: "gamecontroller.fill", value: "\(store.totalActivitiesPlayed)", label: "Sessions")
                miniStat(icon: "clock.fill", value: store.formattedPlayTime, label: "Play time")
                miniStat(icon: "rosette", value: "\(store.unlockedAchievementCount)", label: "Achievements")
                miniStat(icon: "star.fill", value: "\(store.totalStarsEarned)", label: "STARS")
            }
        }
    }

    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.appAccent)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.appTextSecondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .elevatedInset(accent: .appAccent, cornerRadius: 12)
    }
}

struct HomeAchievementsWidget: View {
    @EnvironmentObject private var store: GameProgressStore
    let onSeeAll: () -> Void

    private var progress: Double {
        guard !Achievement.all.isEmpty else { return 0 }
        return Double(store.unlockedAchievementCount) / Double(Achievement.all.count)
    }

    var body: some View {
        HomeWidget(title: "Achievements", icon: "rosette", accent: .appAccent) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.appSurface, lineWidth: 8)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.appPrimary, .appAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progress * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.appTextPrimary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(store.unlockedAchievementCount) of \(Achievement.all.count) unlocked")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.appTextPrimary)
                    if let latest = store.recentAchievements(limit: 1).first {
                        Label(latest.title, systemImage: latest.iconName)
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                    Button("See all", action: onSeeAll)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.appAccent)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

struct HomeActivityChip: View {
    let activity: ActivityDefinition
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            IconBadge(systemName: activity.iconName, size: 44)
            Text(activity.title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
            Text("\(store.totalStarsInActivity(activity.id)) ⭐")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.appAccent)
            GradientProgressBar(
                progress: Double(store.totalStarsInActivity(activity.id)) / Double(store.maxStarsPerActivity),
                height: 4
            )
        }
        .padding(14)
        .frame(width: 140)
        .elevatedSurface(accent: .appPrimary, cornerRadius: AppLayout.cellRadius)
    }
}

struct HomeActivitiesRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick pick")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ActivityDefinition.all) { activity in
                        NavigationLink(value: HomeRoute.activity(activity.id)) {
                            HomeActivityChip(activity: activity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct HomeSeeAllGamesCard: View {
    var body: some View {
        NavigationLink(value: HomeRoute.allGames) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Activities")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("Browse levels and practice mode")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
                Image(systemName: "square.grid.2x2.fill")
                    .font(.title2)
                    .foregroundColor(.appAccent)
            }
            .padding(16)
            .elevatedSurface(accent: .appAccent, cornerRadius: AppLayout.cardRadius)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { HapticService.lightTap() })
    }
}

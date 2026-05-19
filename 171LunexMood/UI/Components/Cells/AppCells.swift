import SwiftUI

// MARK: - Play tab cells

struct DailyGoalCell: View {
    @EnvironmentObject private var store: GameProgressStore

    private var progress: Double {
        min(1, Double(store.dailyStarsEarnedToday) / Double(GameProgressStore.dailyGoalTarget))
    }

    var body: some View {
        AppCard(accent: .appAccent) {
            HStack(alignment: .top, spacing: 14) {
                IconBadge(systemName: "sun.max.fill", accent: .appAccent)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Daily Goal")
                            .font(.headline)
                            .foregroundColor(.appTextPrimary)
                        Spacer()
                        if store.dailyGoalRewardClaimed {
                            statusPill("Badge", icon: "seal.fill")
                        } else if store.isDailyGoalComplete {
                            statusPill("Done", icon: "checkmark")
                        }
                    }
                    Text("Earn \(GameProgressStore.dailyGoalTarget) STARS today")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    GradientProgressBar(progress: progress)
                    HStack {
                        Text("\(store.dailyStarsEarnedToday)")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.appAccent)
                        Text("/ \(GameProgressStore.dailyGoalTarget) STARS ⭐")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
        }
    }

    private func statusPill(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.bold))
            .foregroundColor(.appAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.appAccent.opacity(0.15))
            .clipShape(Capsule())
    }
}

struct StreakCell: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        AppCard(accent: .appAccent) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.appAccent.opacity(0.35), .appPrimary.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 64, height: 64)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.appAccent, .appPrimary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Play Streak")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text(streakSubtitle)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    if store.playStreakDays > 0 {
                        HStack(spacing: 4) {
                            ForEach(0..<min(store.playStreakDays, 7), id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.appAccent)
                                    .frame(width: 8, height: 18)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                Spacer()
                Text("\(store.playStreakDays)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.appAccent)
            }
        }
    }

    private var streakSubtitle: String {
        if store.playStreakDays > 0 {
            return "\(store.playStreakDays) day\(store.playStreakDays == 1 ? "" : "s") in a row"
        }
        return "Play today to start your streak"
    }
}

struct WeeklyChallengeCell: View {
    @EnvironmentObject private var store: GameProgressStore
    let levels: [WeeklyChallengeLevel]

    var body: some View {
        AppCard(accent: .appPrimary) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    IconBadge(systemName: "flag.checkered", size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weekly Challenge")
                            .font(.headline)
                            .foregroundColor(.appTextPrimary)
                        Text("Clear any level below")
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary)
                    }
                    Spacer()
                    if store.weeklyChallengeCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundColor(.appAccent)
                    }
                }
                VStack(spacing: 8) {
                    ForEach(levels) { item in
                        WeeklyChallengeRow(label: item.label)
                    }
                }
            }
        }
    }
}

struct WeeklyChallengeRow: View {
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "star.circle")
                .foregroundColor(.appAccent.opacity(0.8))
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundColor(.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundColor(.appTextSecondary.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .elevatedInset(accent: .appAccent, cornerRadius: 12)
    }
}

struct ActivityListCell: View {
    let activity: ActivityDefinition
    @EnvironmentObject private var store: GameProgressStore

    private var starProgress: Double {
        let total = store.totalStarsInActivity(activity.id)
        let max = store.maxStarsPerActivity
        guard max > 0 else { return 0 }
        return Double(total) / Double(max)
    }

    var body: some View {
        HStack(spacing: 16) {
            IconBadge(systemName: activity.iconName, size: 56)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(activity.title)
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundColor(.appAccent)
                }
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    Label("\(store.totalStarsInActivity(activity.id)) ⭐", systemImage: "star.fill")
                    Text("·")
                    Label("\(store.sessionsPlayed(activityId: activity.id)) plays", systemImage: "repeat")
                }
                .font(.caption2.weight(.medium))
                .foregroundColor(.appTextSecondary)
                GradientProgressBar(progress: starProgress, height: 6)
            }
        }
        .padding(16)
        .elevatedSurface(accent: .appAccent, cornerRadius: AppLayout.cardRadius)
    }
}

// MARK: - Level selection

struct LevelGridCell: View {
    let levelNumber: Int
    let stars: Int
    let best: Int
    let locked: Bool
    let isPractice: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.appTextSecondary.opacity(0.7))
                } else {
                    Text("\(levelNumber)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                }
                if stars == 3, !locked {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.appAccent)
                        .offset(x: 22, y: -22)
                }
            }
            .frame(height: 36)

            StarRatingView(count: stars, size: 12)

            if best > 0, !locked {
                Text("Best \(best)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.appAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.appAccent.opacity(0.12))
                    .clipShape(Capsule())
            } else if isPractice, !locked {
                Text("Practice")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 108)
        .padding(.vertical, 10)
        .elevatedSurface(
            accent: cellAccent,
            cornerRadius: AppLayout.cellRadius,
            showShadow: !locked
        )
        .opacity(locked ? 0.55 : 1)
    }

    private var cellAccent: Color {
        if locked { return .appTextSecondary }
        if stars == 3 { return .appAccent }
        return stars >= 1 ? .appAccent : .appPrimary
    }
}

struct PracticeModeCell: View {
    @Binding var isOn: Bool

    var body: some View {
        AppCard(accent: isOn ? .appAccent : .appPrimary) {
            Toggle(isOn: $isOn) {
                HStack(spacing: 12) {
                    IconBadge(systemName: "figure.run", size: 40, accent: .appAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Practice Mode")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.appTextPrimary)
                        Text("Replay freely — progress is not saved")
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            .tint(.appAccent)
        }
    }
}

struct ActivityHeroHeader: View {
    let activity: ActivityDefinition
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        AppCard {
            HStack(spacing: 16) {
                IconBadge(systemName: activity.iconName, size: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(activity.title)
                        .font(.title2.bold())
                        .foregroundColor(.appTextPrimary)
                    Text(activity.subtitle)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    HStack(spacing: 12) {
                        miniStat(value: "\(store.totalStarsInActivity(activity.id))", label: "STARS")
                        miniStat(value: activity.metricLabel, label: "Metric")
                    }
                }
            }
        }
    }

    private func miniStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundColor(.appAccent)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.appTextSecondary)
        }
    }
}

// MARK: - Achievements

enum AchievementFilter: String, CaseIterable {
    case all = "All"
    case unlocked = "Unlocked"
    case locked = "Locked"
}

struct AchievementGridCell: View {
    let achievement: Achievement
    let unlocked: Bool
    let animate: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        unlocked
                            ? LinearGradient(
                                colors: [.appAccent.opacity(0.4), .appPrimary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.appSurface, Color.appBackground.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: achievement.iconName)
                    .font(.title)
                    .foregroundColor(unlocked ? .appAccent : .appTextSecondary.opacity(0.4))
                if !unlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .padding(6)
                        .background(Color.appSurface)
                        .clipShape(Circle())
                        .offset(x: 26, y: 26)
                }
            }
            .scaleEffect(animate && unlocked ? 1.06 : 1)

            Text(achievement.title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.appTextPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(achievement.description)
                .font(.caption2)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 172)
        .elevatedSurface(
            accent: unlocked ? .appAccent : .appTextSecondary,
            cornerRadius: AppLayout.cardRadius,
            showShadow: unlocked
        )
        .opacity(unlocked ? 1 : 0.72)
        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: animate)
    }
}

// MARK: - Settings

struct StatTileCell: View {
    let icon: String
    let value: String
    let label: String
    var accent: Color = .appAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundColor(accent)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundColor(.appTextSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .elevatedSurface(accent: accent, cornerRadius: AppLayout.cellRadius, kind: .inset, showShadow: false)
    }
}

struct ActivityStatRowCell: View {
    let activity: ActivityDefinition
    let sessions: Int
    let stars: Int
    let maxStars: Int

    private var progress: Double {
        guard maxStars > 0 else { return 0 }
        return Double(stars) / Double(maxStars)
    }

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemName: activity.iconName, size: 40)
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appTextPrimary)
                HStack {
                    Text("\(sessions) sessions")
                    Text("·")
                    Text("\(stars)/\(maxStars) ⭐")
                }
                .font(.caption2)
                .foregroundColor(.appTextSecondary)
                GradientProgressBar(progress: progress, height: 5)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsNavigationCell: View {
    let title: String
    let icon: String
    var tint: Color = .appAccent
    let action: () -> Void

    var body: some View {
        Button {
            HapticService.lightTap()
            action()
        } label: {
            HStack(spacing: 14) {
                IconBadge(systemName: icon, size: 40, accent: tint)
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.appTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(14)
            .elevatedSurface(accent: tint, cornerRadius: AppLayout.cellRadius)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TogglePreferenceCell: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemName: icon, size: 40)
            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(.appTextPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.appAccent)
        }
        .padding(14)
        .elevatedSurface(accent: .appPrimary, cornerRadius: AppLayout.cellRadius)
    }
}

struct DestructiveActionCell: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .foregroundColor(.appAccent)
            .padding(16)
            .elevatedSurface(accent: .appAccent, cornerRadius: AppLayout.cellRadius, kind: .inset, showShadow: false)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

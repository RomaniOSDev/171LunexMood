import SwiftUI

struct GameResultOverlay: View {
    let success: Bool
    let stars: Int
    let starsDelta: Int
    let isPractice: Bool
    let metricTitle: String
    let metricValue: String
    let hasNextLevel: Bool
    let newAchievements: [Achievement]
    let onRetry: () -> Void
    let onBack: () -> Void
    let onNextLevel: () -> Void

    @State private var showFlash = false
    @State private var showBanner = false
    @State private var bannerAchievement: Achievement?
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()

            if showFlash {
                Color.red.opacity(0.45).ignoresSafeArea()
                    .transition(.opacity)
            }

            ScrollView {
                VStack(spacing: 20) {
                    if let bannerAchievement, showBanner {
                        achievementBanner(bannerAchievement)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    resultHeader

                    if success {
                        AnimatedStarsView(count: stars)
                    } else {
                        StarRatingView(count: 0, size: 32)
                    }

                    sessionSummary

                    AppCard(accent: .appAccent) {
                        VStack(spacing: 6) {
                            Text(metricTitle.uppercased())
                                .font(.caption.weight(.bold))
                                .tracking(0.6)
                                .foregroundColor(.appTextSecondary)
                            Text(metricValue)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.appAccent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    VStack(spacing: 12) {
                        if success, hasNextLevel {
                            PrimaryButton(title: "Next Level") {
                                HapticService.mediumImpact()
                                onNextLevel()
                            }
                        }

                        PrimaryButton(title: success ? "Retry" : "Try Again") {
                            onRetry()
                        }

                        PrimaryButton(title: "Back to Levels", style: .secondary) {
                            onBack()
                        }
                    }
                }
                .padding(24)
            }
        }
        .onAppear(perform: handleAppear)
    }

    private var resultHeader: some View {
        VStack(spacing: 8) {
            IconBadge(
                systemName: success ? "checkmark.seal.fill" : "xmark.octagon.fill",
                size: 56,
                accent: success ? .appAccent : .appPrimary
            )
            Text(success ? "Level Complete" : "Game Over")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
            if isPractice {
                Text("Practice — no progress saved")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.appTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appSurface.opacity(0.6))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var sessionSummary: some View {
        if !isPractice {
            AppCard {
                VStack(spacing: 12) {
                    HStack {
                        Label("Session", systemImage: "sparkles")
                            .foregroundColor(.appTextSecondary)
                            .font(.subheadline)
                        Spacer()
                        if starsDelta > 0 {
                            Text("+\(starsDelta) STARS ⭐")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.appAccent)
                        } else {
                            Text("No new STARS")
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    GradientProgressBar(
                        progress: Double(store.dailyStarsEarnedToday) / Double(GameProgressStore.dailyGoalTarget)
                    )
                    HStack {
                        Text("Daily goal")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        Spacer()
                        Text("\(store.dailyStarsEarnedToday)/\(GameProgressStore.dailyGoalTarget)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.appTextPrimary)
                    }
                }
            }
        }
    }

    private func achievementBanner(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            IconBadge(systemName: achievement.iconName, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.appTextSecondary)
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appPrimary.opacity(0.4))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.appAccent.opacity(0.5), lineWidth: 1)
                }
        }
    }

    private func handleAppear() {
        if success {
            SoundService.playSuccess()
            HapticService.success()
        } else {
            SoundService.playFail()
            HapticService.error()
            withAnimation(.easeInOut(duration: 0.15)) { showFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) { showFlash = false }
            }
        }

        if let first = newAchievements.first {
            bannerAchievement = first
            store.markAchievementSeen(first.id)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBanner = false
                }
            }
        }
    }
}

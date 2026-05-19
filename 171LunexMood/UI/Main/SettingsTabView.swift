import SwiftUI
import UIKit

struct SettingsTabView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var showResetAlert = false

    private let statColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        ScreenHeader(
                            title: "Settings",
                            subtitle: "Preferences and your climb statistics",
                            icon: "gearshape.fill"
                        )

                        SectionHeader(title: "Overview")
                        LazyVGrid(columns: statColumns, spacing: 12) {
                            StatTileCell(
                                icon: "figure.walk",
                                value: "\(store.totalActivitiesPlayed)",
                                label: "Sessions"
                            )
                            StatTileCell(
                                icon: "star.fill",
                                value: "\(store.totalStarsEarned)",
                                label: "STARS earned",
                                accent: .appAccent
                            )
                            StatTileCell(
                                icon: "clock.fill",
                                value: store.formattedPlayTime,
                                label: "Play time"
                            )
                            StatTileCell(
                                icon: "flame.fill",
                                value: "\(store.playStreakDays)d",
                                label: "Streak",
                                accent: .appAccent
                            )
                        }

                        SectionHeader(title: "By activity")
                        AppCard {
                            VStack(spacing: 12) {
                                ForEach(ActivityDefinition.all) { activity in
                                    ActivityStatRowCell(
                                        activity: activity,
                                        sessions: store.sessionsPlayed(activityId: activity.id),
                                        stars: store.totalStarsInActivity(activity.id),
                                        maxStars: store.maxStarsPerActivity
                                    )
                                    if activity.id != ActivityDefinition.all.last?.id {
                                        Divider().overlay(Color.appPrimary.opacity(0.2))
                                    }
                                }
                            }
                        }

                        SectionHeader(title: "Preferences")
                        VStack(spacing: 10) {
                            TogglePreferenceCell(
                                title: "Sound Effects",
                                icon: "speaker.wave.2.fill",
                                isOn: $store.soundEnabled
                            )
                            TogglePreferenceCell(
                                title: "Haptics",
                                icon: "iphone.radiowaves.left.and.right",
                                isOn: $store.hapticsEnabled
                            )
                        }

                        SectionHeader(title: "Legal")
                        VStack(spacing: 10) {
                            SettingsNavigationCell(
                                title: "Rate Us",
                                icon: "star.bubble.fill",
                                tint: .appAccent
                            ) {
                                HapticService.lightTap()
                                rateApp()
                            }

                            SettingsNavigationCell(
                                title: AppExternalLink.privacyPolicy.title,
                                icon: AppExternalLink.privacyPolicy.iconName
                            ) {
                                HapticService.lightTap()
                                openPolicy(.privacyPolicy)
                            }

                            SettingsNavigationCell(
                                title: AppExternalLink.termsOfUse.title,
                                icon: AppExternalLink.termsOfUse.iconName
                            ) {
                                HapticService.lightTap()
                                openPolicy(.termsOfUse)
                            }
                        }

                        DestructiveActionCell(title: "Reset All Progress") {
                            HapticService.lightTap()
                            showResetAlert = true
                        }

                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(AppLayout.horizontalPadding)
                    .padding(.bottom, 28)
                }
                .appScrollStyle()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarHidden(true)
            .appNavigationStyle()
            .alert("Reset All Progress?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAllProgress()
                    HapticService.error()
                }
            } message: {
                Text("This will erase all stars, levels, and statistics.")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func openPolicy(_ link: AppExternalLink) {
        if let url = URL(string: link.rawValue) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        AppStoreActions.rateApp()
    }
}

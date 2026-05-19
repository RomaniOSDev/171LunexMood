import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let isUnlocked: (GameProgressStore) -> Bool

    static let all: [Achievement] = [
        Achievement(
            id: "first_step",
            title: "First Step",
            description: "Earned your first star.",
            iconName: "star.fill",
            isUnlocked: { $0.totalStarsEarned >= 1 }
        ),
        Achievement(
            id: "rookie_climber",
            title: "Rookie Climber",
            description: "Played five activities.",
            iconName: "figure.walk",
            isUnlocked: { $0.totalActivitiesPlayed >= 5 }
        ),
        Achievement(
            id: "steady_ascent",
            title: "Steady Ascent",
            description: "Climbed for 500 seconds.",
            iconName: "clock.fill",
            isUnlocked: { $0.totalPlayTimeSeconds >= 500 }
        ),
        Achievement(
            id: "star_collector",
            title: "Star Collector",
            description: "Earned 25 stars total.",
            iconName: "star.circle.fill",
            isUnlocked: { $0.totalStarsEarned >= 25 }
        ),
        Achievement(
            id: "star_master",
            title: "Star Master",
            description: "Earned 75 stars total.",
            iconName: "sparkles",
            isUnlocked: { $0.totalStarsEarned >= 75 }
        ),
        Achievement(
            id: "active_player",
            title: "Active Player",
            description: "Completed 25 activity sessions.",
            iconName: "flame.fill",
            isUnlocked: { $0.totalActivitiesPlayed >= 25 }
        ),
        Achievement(
            id: "hundred_plays",
            title: "Hundred Plays",
            description: "Completed 100 activity sessions.",
            iconName: "repeat.circle.fill",
            isUnlocked: { $0.totalActivitiesPlayed >= 100 }
        ),
        Achievement(
            id: "perfectionist",
            title: "Perfectionist",
            description: "Earned 3 stars on any single level.",
            iconName: "crown.fill",
            isUnlocked: { $0.hasAnyThreeStarLevel }
        ),
        Achievement(
            id: "daily_climber",
            title: "Daily Climber",
            description: "Reached the daily STARS goal.",
            iconName: "sun.max.fill",
            isUnlocked: { $0.dailyGoalRewardClaimed }
        ),
        Achievement(
            id: "streak_starter",
            title: "Streak Starter",
            description: "Played on 3 days in a row.",
            iconName: "calendar",
            isUnlocked: { $0.playStreakDays >= 3 }
        ),
        Achievement(
            id: "streak_master",
            title: "Streak Master",
            description: "Played on 7 days in a row.",
            iconName: "calendar.badge.clock",
            isUnlocked: { $0.playStreakDays >= 7 }
        ),
        Achievement(
            id: "easy_clear",
            title: "Easy Does It",
            description: "Cleared any level on Easy.",
            iconName: "leaf.fill",
            isUnlocked: { store in
                store.starsPerActivity.values.contains { difficulties in
                    difficulties[Difficulty.easy.rawValue]?.contains(where: { $0 >= 1 }) == true
                }
            }
        ),
        Achievement(
            id: "hard_mode",
            title: "Hard Mode Hero",
            description: "Earned stars on a Hard level.",
            iconName: "bolt.fill",
            isUnlocked: { store in
                store.starsPerActivity.values.contains { difficulties in
                    difficulties[Difficulty.hard.rawValue]?.contains(where: { $0 >= 1 }) == true
                }
            }
        ),
        Achievement(
            id: "weekly_warrior",
            title: "Weekly Warrior",
            description: "Completed this week's challenge.",
            iconName: "flag.checkered",
            isUnlocked: { $0.weeklyChallengeCompleted }
        ),
        Achievement(
            id: "sprint_specialist",
            title: "Sprint Specialist",
            description: "Played Star Sprint 10 times.",
            iconName: "timer",
            isUnlocked: { $0.sessionsPlayed(activityId: "star_sprint") >= 10 }
        ),
        Achievement(
            id: "sky_master",
            title: "Sky Master",
            description: "Played Skybound Stride 20 times.",
            iconName: "figure.climbing",
            isUnlocked: { $0.sessionsPlayed(activityId: "skybound_stride") >= 20 }
        )
    ]
}

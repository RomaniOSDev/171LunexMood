import Foundation

struct WeeklyChallengeLevel: Identifiable, Hashable {
    let id = UUID()
    let activityId: String
    let difficulty: Difficulty
    let level: Int

    var label: String {
        let activity = ActivityDefinition.find(id: activityId)?.title ?? "Activity"
        return "\(activity) · \(difficulty.title) · L\(level + 1)"
    }
}

enum WeeklyChallenge {
    static let levelCount = 3

    static func currentWeekIndex() -> Int {
        let calendar = Calendar.current
        let week = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.yearForWeekOfYear, from: Date())
        return year * 100 + week
    }

    static func levelsForCurrentWeek() -> [WeeklyChallengeLevel] {
        let week = currentWeekIndex()
        let activities = ActivityDefinition.all.map(\.id)
        return (0..<levelCount).map { index in
            let seed = week &+ index &+ 17
            let activityId = activities[seed % activities.count]
            let difficulty = Difficulty.allCases[seed % Difficulty.allCases.count]
            let level = seed % Difficulty.levelCount
            return WeeklyChallengeLevel(activityId: activityId, difficulty: difficulty, level: level)
        }
    }
}

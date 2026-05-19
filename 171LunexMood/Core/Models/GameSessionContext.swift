import Foundation

struct GameSessionContext: Hashable {
    let activityId: String
    let difficulty: Difficulty
    let level: Int
    var isPractice: Bool = false
}

struct LevelResultPayload {
    let starsEarned: Int
    let starsDelta: Int
    let metricValue: String
    let metricTitle: String
    let newAchievements: [Achievement]
}

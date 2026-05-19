import Combine
import Foundation

final class GameProgressStore: ObservableObject {
    static let shared = GameProgressStore()
    static let dailyGoalTarget = 15

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let totalActivitiesPlayed = "totalActivitiesPlayed"
        static let totalStarsEarned = "totalStarsEarned"
        static let totalPlayTimeSeconds = "totalPlayTimeSeconds"
        static let starsPerActivity = "starsPerActivity"
        static let unlockedLevels = "unlockedLevels"
        static let bestScoresPerActivity = "bestScoresPerActivity"
        static let playStreakDays = "playStreakDays"
        static let lastPlayDayKey = "lastPlayDayKey"
        static let dailyStarsDateKey = "dailyStarsDateKey"
        static let dailyStarsEarnedToday = "dailyStarsEarnedToday"
        static let dailyGoalRewardClaimed = "dailyGoalRewardClaimed"
        static let seenAchievementIDs = "seenAchievementIDs"
        static let seenActivityTutorials = "seenActivityTutorials"
        static let soundEnabled = "soundEnabled"
        static let hapticsEnabled = "hapticsEnabled"
        static let weeklyChallengeWeek = "weeklyChallengeWeek"
        static let weeklyChallengeCompleted = "weeklyChallengeCompleted"
        static let activitySessionsPlayed = "activitySessionsPlayed"
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var totalActivitiesPlayed: Int {
        didSet { defaults.set(totalActivitiesPlayed, forKey: Keys.totalActivitiesPlayed) }
    }

    @Published var totalStarsEarned: Int {
        didSet { defaults.set(totalStarsEarned, forKey: Keys.totalStarsEarned) }
    }

    @Published var totalPlayTimeSeconds: Int {
        didSet { defaults.set(totalPlayTimeSeconds, forKey: Keys.totalPlayTimeSeconds) }
    }

    @Published var starsPerActivity: [String: [String: [Int]]] {
        didSet { saveJSON(starsPerActivity, key: Keys.starsPerActivity) }
    }

    @Published var unlockedLevels: [String: [String: Int]] {
        didSet { saveJSON(unlockedLevels, key: Keys.unlockedLevels) }
    }

    @Published var bestScoresPerActivity: [String: [String: [Int]]] {
        didSet { saveJSON(bestScoresPerActivity, key: Keys.bestScoresPerActivity) }
    }

    @Published var playStreakDays: Int {
        didSet { defaults.set(playStreakDays, forKey: Keys.playStreakDays) }
    }

    @Published var dailyStarsEarnedToday: Int {
        didSet { defaults.set(dailyStarsEarnedToday, forKey: Keys.dailyStarsEarnedToday) }
    }

    @Published var dailyGoalRewardClaimed: Bool {
        didSet { defaults.set(dailyGoalRewardClaimed, forKey: Keys.dailyGoalRewardClaimed) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    @Published var weeklyChallengeCompleted: Bool {
        didSet { defaults.set(weeklyChallengeCompleted, forKey: Keys.weeklyChallengeCompleted) }
    }

    @Published var activitySessionsPlayed: [String: Int] {
        didSet { saveJSON(activitySessionsPlayed, key: Keys.activitySessionsPlayed) }
    }

    @Published private(set) var seenAchievementIDs: Set<String> {
        didSet { defaults.set(Array(seenAchievementIDs), forKey: Keys.seenAchievementIDs) }
    }

    @Published private(set) var seenActivityTutorials: Set<String> {
        didSet { defaults.set(Array(seenActivityTutorials), forKey: Keys.seenActivityTutorials) }
    }

    private let defaults: UserDefaults
    private var dailyStarsDateKey: String {
        didSet { defaults.set(dailyStarsDateKey, forKey: Keys.dailyStarsDateKey) }
    }

    private var lastPlayDayKey: String {
        didSet { defaults.set(lastPlayDayKey, forKey: Keys.lastPlayDayKey) }
    }

    private var weeklyChallengeWeek: Int {
        didSet { defaults.set(weeklyChallengeWeek, forKey: Keys.weeklyChallengeWeek) }
    }

    var hasAnyThreeStarLevel: Bool {
        starsPerActivity.values.flatMap { $0.values }.flatMap { $0 }.contains(3)
    }

    var formattedPlayTime: String {
        let hours = totalPlayTimeSeconds / 3600
        let minutes = (totalPlayTimeSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var isDailyGoalComplete: Bool {
        refreshDailyGoalIfNeeded()
        return dailyStarsEarnedToday >= Self.dailyGoalTarget
    }

    var dailyGoalProgress: Double {
        refreshDailyGoalIfNeeded()
        guard Self.dailyGoalTarget > 0 else { return 0 }
        return min(1, Double(dailyStarsEarnedToday) / Double(Self.dailyGoalTarget))
    }

    var levelsClearedCount: Int {
        starsPerActivity.values
            .flatMap(\.values)
            .flatMap { $0 }
            .filter { $0 >= 1 }
            .count
    }

    var favoriteActivity: ActivityDefinition? {
        ActivityDefinition.all.max { lhs, rhs in
            sessionsPlayed(activityId: lhs.id) < sessionsPlayed(activityId: rhs.id)
        }
    }

    func suggestedPlay() -> SuggestedPlay {
        for activity in ActivityDefinition.all {
            for difficulty in Difficulty.allCases {
                for level in 0..<Difficulty.levelCount {
                    guard isLevelUnlocked(activityId: activity.id, difficulty: difficulty, level: level) else {
                        continue
                    }
                    if stars(activityId: activity.id, difficulty: difficulty, level: level) < 3 {
                        return SuggestedPlay(activityId: activity.id, difficulty: difficulty, level: level)
                    }
                }
            }
        }
        let fallback = favoriteActivity ?? ActivityDefinition.all[0]
        return SuggestedPlay(activityId: fallback.id, difficulty: .easy, level: 0)
    }

    func recentAchievements(limit: Int = 3) -> [Achievement] {
        Achievement.all
            .filter { $0.isUnlocked(self) }
            .prefix(limit)
            .map { $0 }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalActivitiesPlayed = defaults.integer(forKey: Keys.totalActivitiesPlayed)
        totalStarsEarned = defaults.integer(forKey: Keys.totalStarsEarned)
        totalPlayTimeSeconds = defaults.integer(forKey: Keys.totalPlayTimeSeconds)
        playStreakDays = defaults.integer(forKey: Keys.playStreakDays)
        dailyStarsEarnedToday = defaults.integer(forKey: Keys.dailyStarsEarnedToday)
        dailyGoalRewardClaimed = defaults.bool(forKey: Keys.dailyGoalRewardClaimed)
        soundEnabled = defaults.object(forKey: Keys.soundEnabled) == nil ? true : defaults.bool(forKey: Keys.soundEnabled)
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) == nil ? true : defaults.bool(forKey: Keys.hapticsEnabled)
        weeklyChallengeCompleted = defaults.bool(forKey: Keys.weeklyChallengeCompleted)
        dailyStarsDateKey = defaults.string(forKey: Keys.dailyStarsDateKey) ?? ""
        lastPlayDayKey = defaults.string(forKey: Keys.lastPlayDayKey) ?? ""
        weeklyChallengeWeek = defaults.integer(forKey: Keys.weeklyChallengeWeek)
        starsPerActivity = Self.loadStarsMap(key: Keys.starsPerActivity, defaults: defaults)
        unlockedLevels = Self.loadUnlockMap(key: Keys.unlockedLevels, defaults: defaults)
        bestScoresPerActivity = Self.loadStarsMap(key: Keys.bestScoresPerActivity, defaults: defaults)
        activitySessionsPlayed = Self.loadStringIntMap(key: Keys.activitySessionsPlayed, defaults: defaults)
        seenAchievementIDs = Set(defaults.stringArray(forKey: Keys.seenAchievementIDs) ?? [])
        seenActivityTutorials = Set(defaults.stringArray(forKey: Keys.seenActivityTutorials) ?? [])

        refreshDailyGoalIfNeeded()
        refreshWeeklyChallengeIfNeeded()

        NotificationCenter.default.addObserver(
            forName: .progressReset,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadFromDefaults()
        }
    }

    func stars(activityId: String, difficulty: Difficulty, level: Int) -> Int {
        starsPerActivity[activityId]?[difficulty.rawValue]?[safe: level] ?? 0
    }

    func bestScore(activityId: String, difficulty: Difficulty, level: Int) -> Int {
        bestScoresPerActivity[activityId]?[difficulty.rawValue]?[safe: level] ?? 0
    }

    func sessionsPlayed(activityId: String) -> Int {
        activitySessionsPlayed[activityId] ?? 0
    }

    func isLevelUnlocked(activityId: String, difficulty: Difficulty, level: Int) -> Bool {
        if level == 0 { return true }
        let highest = unlockedLevels[activityId]?[difficulty.rawValue] ?? 0
        return level <= highest
    }

    func hasSeenTutorial(activityId: String) -> Bool {
        seenActivityTutorials.contains(activityId)
    }

    func markTutorialSeen(activityId: String) {
        seenActivityTutorials.insert(activityId)
    }

    @discardableResult
    func recordLevelResult(
        activityId: String,
        difficulty: Difficulty,
        level: Int,
        stars earned: Int,
        metricScore: Int,
        playSeconds: Int,
        isPractice: Bool
    ) -> LevelResultPayload {
        refreshDailyGoalIfNeeded()
        registerPlayDay()

        let previousStars = stars(activityId: activityId, difficulty: difficulty, level: level)
        var starsDelta = 0
        var newAchievements: [Achievement] = []

        if !isPractice {
            starsDelta = max(0, earned - previousStars)
            updateStars(activityId: activityId, difficulty: difficulty, level: level, earned: earned)
            updateUnlocks(activityId: activityId, difficulty: difficulty, level: level, earned: earned)
            updateBestScore(activityId: activityId, difficulty: difficulty, level: level, score: metricScore)

            totalActivitiesPlayed += 1
            activitySessionsPlayed[activityId, default: 0] += 1
            totalStarsEarned += starsDelta
            totalPlayTimeSeconds += playSeconds
            dailyStarsEarnedToday += starsDelta

            if isDailyGoalComplete, !dailyGoalRewardClaimed {
                dailyGoalRewardClaimed = true
            }

            newAchievements = newlyUnlockedAchievements()
            checkWeeklyChallengeCompletion(activityId: activityId, difficulty: difficulty, level: level, earned: earned)
        }

        return LevelResultPayload(
            starsEarned: earned,
            starsDelta: starsDelta,
            metricValue: "\(metricScore)",
            metricTitle: ActivityDefinition.find(id: activityId)?.metricLabel ?? "Score",
            newAchievements: newAchievements
        )
    }

    func markAchievementSeen(_ id: String) {
        seenAchievementIDs.insert(id)
    }

    func newlyUnlockedAchievements() -> [Achievement] {
        Achievement.all.filter { $0.isUnlocked(self) && !seenAchievementIDs.contains($0.id) }
    }

    func refreshDailyGoalIfNeeded() {
        let today = Self.dayKey()
        if dailyStarsDateKey != today {
            dailyStarsDateKey = today
            dailyStarsEarnedToday = 0
            dailyGoalRewardClaimed = false
        }
    }

    func refreshWeeklyChallengeIfNeeded() {
        let week = WeeklyChallenge.currentWeekIndex()
        if weeklyChallengeWeek != week {
            weeklyChallengeWeek = week
            weeklyChallengeCompleted = false
        }
    }

    func resetAllProgress() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        reloadFromDefaults()
        NotificationCenter.default.post(name: .progressReset, object: nil)
    }

    private func registerPlayDay() {
        let today = Self.dayKey()
        if lastPlayDayKey == today { return }

        if let last = lastPlayDayKey.isEmpty ? nil : lastPlayDayKey,
           Self.isYesterday(last, comparedTo: today) {
            playStreakDays += 1
        } else if lastPlayDayKey != today {
            playStreakDays = 1
        }
        lastPlayDayKey = today
    }

    private func updateStars(activityId: String, difficulty: Difficulty, level: Int, earned: Int) {
        var activityStars = starsPerActivity[activityId] ?? [:]
        var difficultyStars = activityStars[difficulty.rawValue] ?? Array(repeating: 0, count: Difficulty.levelCount)
        while difficultyStars.count < Difficulty.levelCount { difficultyStars.append(0) }
        difficultyStars[level] = max(difficultyStars[level], earned)
        activityStars[difficulty.rawValue] = difficultyStars
        starsPerActivity[activityId] = activityStars
    }

    private func updateUnlocks(activityId: String, difficulty: Difficulty, level: Int, earned: Int) {
        guard earned >= 1, level + 1 < Difficulty.levelCount else { return }
        var activityUnlocks = unlockedLevels[activityId] ?? [:]
        let current = activityUnlocks[difficulty.rawValue] ?? 0
        activityUnlocks[difficulty.rawValue] = max(current, level + 1)
        unlockedLevels[activityId] = activityUnlocks
    }

    private func updateBestScore(activityId: String, difficulty: Difficulty, level: Int, score: Int) {
        var activityBest = bestScoresPerActivity[activityId] ?? [:]
        var difficultyBest = activityBest[difficulty.rawValue] ?? Array(repeating: 0, count: Difficulty.levelCount)
        while difficultyBest.count < Difficulty.levelCount { difficultyBest.append(0) }
        difficultyBest[level] = max(difficultyBest[level], score)
        activityBest[difficulty.rawValue] = difficultyBest
        bestScoresPerActivity[activityId] = activityBest
    }

    private func checkWeeklyChallengeCompletion(
        activityId: String,
        difficulty: Difficulty,
        level: Int,
        earned: Int
    ) {
        guard earned >= 1 else { return }
        let targets = WeeklyChallenge.levelsForCurrentWeek()
        let match = targets.contains { $0.activityId == activityId && $0.difficulty == difficulty && $0.level == level }
        if match {
            weeklyChallengeCompleted = true
        }
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        totalActivitiesPlayed = defaults.integer(forKey: Keys.totalActivitiesPlayed)
        totalStarsEarned = defaults.integer(forKey: Keys.totalStarsEarned)
        totalPlayTimeSeconds = defaults.integer(forKey: Keys.totalPlayTimeSeconds)
        playStreakDays = defaults.integer(forKey: Keys.playStreakDays)
        dailyStarsEarnedToday = defaults.integer(forKey: Keys.dailyStarsEarnedToday)
        dailyGoalRewardClaimed = defaults.bool(forKey: Keys.dailyGoalRewardClaimed)
        soundEnabled = defaults.object(forKey: Keys.soundEnabled) == nil ? true : defaults.bool(forKey: Keys.soundEnabled)
        hapticsEnabled = defaults.object(forKey: Keys.hapticsEnabled) == nil ? true : defaults.bool(forKey: Keys.hapticsEnabled)
        weeklyChallengeCompleted = defaults.bool(forKey: Keys.weeklyChallengeCompleted)
        dailyStarsDateKey = defaults.string(forKey: Keys.dailyStarsDateKey) ?? ""
        lastPlayDayKey = defaults.string(forKey: Keys.lastPlayDayKey) ?? ""
        weeklyChallengeWeek = defaults.integer(forKey: Keys.weeklyChallengeWeek)
        starsPerActivity = Self.loadStarsMap(key: Keys.starsPerActivity, defaults: defaults)
        unlockedLevels = Self.loadUnlockMap(key: Keys.unlockedLevels, defaults: defaults)
        bestScoresPerActivity = Self.loadStarsMap(key: Keys.bestScoresPerActivity, defaults: defaults)
        activitySessionsPlayed = Self.loadStringIntMap(key: Keys.activitySessionsPlayed, defaults: defaults)
        seenAchievementIDs = Set(defaults.stringArray(forKey: Keys.seenAchievementIDs) ?? [])
        seenActivityTutorials = Set(defaults.stringArray(forKey: Keys.seenActivityTutorials) ?? [])
        refreshDailyGoalIfNeeded()
        refreshWeeklyChallengeIfNeeded()
    }

    private static func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func isYesterday(_ previousDay: String, comparedTo today: String) -> Bool {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let prev = formatter.date(from: previousDay),
              let todayDate = formatter.date(from: today),
              let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: todayDate) else {
            return false
        }
        return Calendar.current.isDate(prev, inSameDayAs: yesterday)
    }

    private static func loadStarsMap(key: String, defaults: UserDefaults) -> [String: [String: [Int]]] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [String: [Int]]].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func loadUnlockMap(key: String, defaults: UserDefaults) -> [String: [String: Int]] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private static func loadStringIntMap(key: String, defaults: UserDefaults) -> [String: Int] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func saveJSON<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

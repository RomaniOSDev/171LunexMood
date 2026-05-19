import Combine
import Foundation
import SwiftUI

struct SprintStar: Identifiable {
    let id = UUID()
    var lane: Int
    var y: CGFloat
    var collected = false
}

@MainActor
final class StarSprintViewModel: ObservableObject {
    @Published var playerLane = 1
    @Published var starsCollected = 0
    @Published var timeRemaining: CGFloat = 30
    @Published var fallingStars: [SprintStar] = []
    @Published var isGameOver = false
    @Published var showResult = false
    @Published var earnedStars = 0
    @Published var starsDelta = 0
    @Published var sessionSuccess = false
    @Published var newAchievements: [Achievement] = []
    @Published var layout = GameLaneLayout(width: 390, height: 844)
    @Published var statusMessage = "Swipe lanes • Collect STARS ⭐"
    @Published var isPaused = false
    @Published private(set) var isRunning = false

    let difficulty: Difficulty
    let level: Int
    let activityId = "star_sprint"
    var isPractice = false

    private var gameTimer: AnyCancellable?
    private var spawnTimer: AnyCancellable?
    private let playTime = PlayTimeTracker()
    private var spawnTick = 0

    private var fallSpeed: CGFloat {
        let base: CGFloat
        switch difficulty {
        case .easy: base = 2.2
        case .normal: base = 3.0
        case .hard: base = 3.8
        }
        return base + CGFloat(level) * 0.15
    }

    private var starGoal: Int {
        8 + level * 2
    }

    init(difficulty: Difficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
    }

    func startGame(layout: GameLaneLayout) {
        guard layout.width > 50, layout.height > 50 else { return }
        stopGame()
        self.layout = layout
        reset()
        isRunning = true
        playTime.reset()

        gameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }

        let interval: TimeInterval
        switch difficulty {
        case .easy: interval = 1.1
        case .normal: interval = 0.85
        case .hard: interval = 0.65
        }
        spawnTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.spawnStar() }
    }

    func stopGame() {
        gameTimer?.cancel()
        spawnTimer?.cancel()
        gameTimer = nil
        spawnTimer = nil
        isRunning = false
    }

    func togglePause() {
        guard isRunning, !isGameOver else { return }
        if isPaused {
            isPaused = false
            playTime.endPause()
            resumeTimers()
        } else {
            isPaused = true
            playTime.beginPause()
            gameTimer?.cancel()
            spawnTimer?.cancel()
            gameTimer = nil
            spawnTimer = nil
        }
    }

    func shiftLane(_ direction: Int) {
        guard isRunning, !isGameOver, !isPaused else { return }
        playerLane = min(2, max(0, playerLane + direction))
        HapticService.lightTap()
    }

    func starsForCount(_ count: Int) -> Int {
        let goal = starGoal
        if count >= goal + 4 { return 3 }
        if count >= goal { return 2 }
        if count >= max(3, goal - 3) { return 1 }
        return 0
    }

    func triggerEnd(success: Bool) {
        guard !isGameOver else { return }
        sessionSuccess = success
        isGameOver = true
        stopGame()
        statusMessage = success ? "Time's up — great run!" : "Time's up"
    }

    func completeSession(store: GameProgressStore) {
        guard !showResult else { return }
        earnedStars = starsForCount(starsCollected)
        sessionSuccess = earnedStars > 0
        let payload = store.recordLevelResult(
            activityId: activityId,
            difficulty: difficulty,
            level: level,
            stars: earnedStars,
            metricScore: starsCollected,
            playSeconds: playTime.activeSeconds,
            isPractice: isPractice
        )
        starsDelta = payload.starsDelta
        newAchievements = payload.newAchievements
        showResult = true
    }

    private func reset() {
        playerLane = 1
        starsCollected = 0
        timeRemaining = 30
        fallingStars = []
        isGameOver = false
        showResult = false
        spawnTick = 0
        isPaused = false
    }

    private func resumeTimers() {
        gameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
        let interval: TimeInterval
        switch difficulty {
        case .easy: interval = 1.1
        case .normal: interval = 0.85
        case .hard: interval = 0.65
        }
        spawnTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.spawnStar() }
    }

    private func tick() {
        guard isRunning, !isGameOver, !isPaused else { return }
        timeRemaining -= 1.0 / 60.0

        for index in fallingStars.indices where !fallingStars[index].collected {
            fallingStars[index].y += fallSpeed
        }
        fallingStars.removeAll { $0.y > layout.despawnY && $0.collected }

        checkCollection()

        if timeRemaining <= 0 {
            triggerEnd(success: starsCollected >= max(3, starGoal - 3))
        }
    }

    private func spawnStar() {
        guard isRunning, !isGameOver, !isPaused else { return }
        spawnTick += 1
        let lane = spawnTick % 3
        fallingStars.append(SprintStar(lane: lane, y: layout.spawnY))
    }

    private func checkCollection() {
        let half = layout.playerSize / 2
        let playerRect = CGRect(
            x: layout.laneX(playerLane) - half,
            y: layout.playerY - half,
            width: layout.playerSize,
            height: layout.playerSize
        )

        for index in fallingStars.indices where !fallingStars[index].collected {
            let star = fallingStars[index]
            let rect = CGRect(
                x: layout.laneX(star.lane) - 16,
                y: star.y,
                width: 32,
                height: 32
            )
            if playerRect.intersects(rect) {
                fallingStars[index].collected = true
                starsCollected += 1
                statusMessage = "STARS: \(starsCollected)"
                HapticService.success()
                SoundService.playSuccess()
            }
        }
    }
}

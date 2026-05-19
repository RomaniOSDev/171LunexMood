import Combine
import Foundation
import SwiftUI

struct StrideObstacle: Identifiable {
    let id = UUID()
    var lane: Int
    var y: CGFloat
    var isHigh: Bool
}

struct StrideStar: Identifiable {
    let id = UUID()
    var lane: Int
    var y: CGFloat
    var collected = false
}

@MainActor
final class SkyboundStrideViewModel: ObservableObject {
    @Published var playerLane = 1
    @Published var isAirborne = false
    @Published var score = 0
    @Published var obstacles: [StrideObstacle] = []
    @Published var stars: [StrideStar] = []
    @Published var isGameOver = false
    @Published var showResult = false
    @Published var earnedStars = 0
    @Published var sessionSuccess = false
    @Published var newAchievements: [Achievement] = []
    @Published var starsDelta = 0
    @Published var layout = GameLaneLayout(width: 390, height: 844)
    @Published var statusMessage = "Tap to jump • Swipe to switch lanes"
    @Published var isPaused = false
    @Published private(set) var isRunning = false

    let difficulty: Difficulty
    let level: Int
    let activityId = "skybound_stride"
    var isPractice = false

    private var gameTimer: AnyCancellable?
    private var spawnTimer: AnyCancellable?
    private let playTime = PlayTimeTracker()
    private var lastTapTime: Date?
    private var airborneRemaining: CGFloat = 0
    private var spawnIndex = 0
    private var elapsed: CGFloat = 0
    private var bonusScore = 0

    private var gracePeriod: CGFloat {
        switch difficulty {
        case .easy: return 3.5
        case .normal: return 2.5
        case .hard: return 2.0
        }
    }

    private var spawnDelay: CGFloat {
        switch difficulty {
        case .easy: return 2.0
        case .normal: return 1.4
        case .hard: return 1.0
        }
    }

    var goalScore: Int {
        targetScore
    }

    private var targetScore: Int {
        let base: Int
        switch difficulty {
        case .easy: base = 35
        case .normal: base = 50
        case .hard: base = 60
        }
        return base + level * 15
    }

    private var fallSpeed: CGFloat {
        let base: CGFloat
        switch difficulty {
        case .easy: base = 2.0
        case .normal: base = 2.8
        case .hard: base = 3.5
        }
        return base + CGFloat(level) * 0.2
    }

    private var spawnInterval: TimeInterval {
        let base: TimeInterval
        switch difficulty {
        case .easy: base = 2.6
        case .normal: base = 2.0
        case .hard: base = 1.4
        }
        return max(0.9, base - Double(level) * 0.1)
    }

    private var heightPerSecond: CGFloat {
        let base: CGFloat
        switch difficulty {
        case .easy: base = 12
        case .normal: base = 10
        case .hard: base = 11
        }
        return base + CGFloat(level) * 1.5
    }

    private var jumpDuration: (single: CGFloat, double: CGFloat) {
        switch difficulty {
        case .easy: return (0.6, 0.95)
        case .normal: return (0.5, 0.8)
        case .hard: return (0.45, 0.7)
        }
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

        spawnTimer = Timer.publish(every: spawnInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.spawnWave() }

        statusMessage = "Get ready..."
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

    private func resumeTimers() {
        gameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
        spawnTimer = Timer.publish(every: spawnInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.spawnWave() }
    }

    func handleTap() {
        guard isRunning, !isGameOver, !isPaused else { return }
        HapticService.mediumImpact()
        let now = Date()
        let isDouble = lastTapTime.map { now.timeIntervalSince($0) < 0.35 } ?? false
        lastTapTime = now
        isAirborne = true
        let durations = jumpDuration
        airborneRemaining = isDouble ? durations.double : durations.single
        statusMessage = isDouble ? "Long jump!" : "Jump!"
    }

    func shiftLane(_ direction: Int) {
        guard isRunning, !isGameOver, !isPaused else { return }
        let next = min(2, max(0, playerLane + direction))
        guard next != playerLane else { return }
        playerLane = next
        HapticService.lightTap()
    }

    func starsForScore(_ value: Int) -> Int {
        let goal = targetScore
        if value >= goal + 40 { return 3 }
        if value >= goal + 15 { return 2 }
        if value >= goal { return 1 }
        return 0
    }

    func triggerEnd(success: Bool) {
        guard !isGameOver else { return }
        sessionSuccess = success
        isGameOver = true
        stopGame()
        statusMessage = success ? "Tower cleared!" : "Hit an obstacle"
    }

    func completeSession(store: GameProgressStore) {
        guard !showResult else { return }
        earnedStars = sessionSuccess ? starsForScore(score) : 0
        let payload = store.recordLevelResult(
            activityId: activityId,
            difficulty: difficulty,
            level: level,
            stars: earnedStars,
            metricScore: score,
            playSeconds: playTime.activeSeconds,
            isPractice: isPractice
        )
        starsDelta = payload.starsDelta
        newAchievements = payload.newAchievements
        showResult = true
    }

    private func reset() {
        playerLane = 1
        isAirborne = false
        airborneRemaining = 0
        score = 0
        bonusScore = 0
        obstacles = []
        stars = []
        isGameOver = false
        showResult = false
        isPaused = false
        spawnIndex = 0
        elapsed = 0
    }

    private func tick() {
        guard isRunning, !isGameOver, !isPaused else { return }
        elapsed += 1.0 / 60.0

        if elapsed < gracePeriod {
            statusMessage = "Get ready..."
        } else if elapsed < gracePeriod + 0.5 {
            statusMessage = "Tap to jump • Swipe to switch lanes"
        }

        if airborneRemaining > 0 {
            airborneRemaining -= 1.0 / 60.0
            if airborneRemaining <= 0 {
                isAirborne = false
            }
        }

        for index in obstacles.indices {
            obstacles[index].y += fallSpeed
        }
        obstacles.removeAll { $0.y > layout.despawnY }

        for index in stars.indices where !stars[index].collected {
            stars[index].y += fallSpeed
        }
        stars.removeAll { $0.y > layout.despawnY && $0.collected }

        let baseHeight = Int(elapsed * heightPerSecond)
        score = min(999, baseHeight + bonusScore)

        if elapsed >= gracePeriod {
            checkCollisions()
        }

        if score >= targetScore {
            triggerEnd(success: true)
        }
    }

    private func spawnWave() {
        guard isRunning, !isGameOver, !isPaused, elapsed >= gracePeriod + 0.8 else { return }
        spawnIndex += 1

        // Первые волны на Easy — только боковые низкие шипы (средняя полоса свободна).
        if difficulty == .easy, spawnIndex <= 3 {
            obstacles.append(StrideObstacle(lane: 0, y: layout.spawnY, isHigh: false))
            obstacles.append(StrideObstacle(lane: 2, y: layout.spawnY, isHigh: false))
            return
        }

        let pattern = spawnIndex % 4
        switch pattern {
        case 0:
            obstacles.append(StrideObstacle(lane: 0, y: layout.spawnY, isHigh: false))
            obstacles.append(StrideObstacle(lane: 2, y: layout.spawnY, isHigh: false))
        case 1:
            // Высокий шип — не в полосе игрока; нужен прыжок (лучше double-tap).
            let highLane = [0, 2].first { $0 != playerLane } ?? 0
            obstacles.append(StrideObstacle(lane: highLane, y: layout.spawnY, isHigh: true))
            let starLane = [0, 1, 2].first { $0 != highLane } ?? 1
            stars.append(StrideStar(lane: starLane, y: layout.spawnY - 40))
        case 2:
            let dangerLane = [0, 1, 2].first { $0 != playerLane } ?? 1
            obstacles.append(StrideObstacle(lane: dangerLane, y: layout.spawnY, isHigh: false))
        default:
            let highLane = playerLane == 1 ? 2 : 1
            obstacles.append(StrideObstacle(lane: highLane, y: layout.spawnY, isHigh: true))
            stars.append(StrideStar(lane: 1, y: layout.spawnY - 40))
        }
    }

    private func checkCollisions() {
        let half = layout.playerSize / 2
        let playerRect = CGRect(
            x: layout.laneX(playerLane) - half,
            y: layout.playerY - half,
            width: layout.playerSize,
            height: layout.playerSize
        )

        for obstacle in obstacles {
            guard obstacle.lane == playerLane else { continue }

            let obstacleHeight: CGFloat = obstacle.isHigh ? 44 : 28
            // Совпадает с отрисовкой: position.y = obstacle.y + (high ? 22 : 14), tip наверху.
            let visualCenterY = obstacle.y + (obstacle.isHigh ? 22 : 14)
            let obstacleTop = visualCenterY - obstacleHeight / 2
            let obstacleBottom = visualCenterY + obstacleHeight / 2

            let overlapMargin: CGFloat = 8
            guard obstacleBottom >= playerRect.minY - overlapMargin,
                  obstacleTop <= playerRect.maxY + overlapMargin else { continue }

            if obstacle.isHigh {
                // Высокий шип: на земле — удар; в прыжке — перелетаете.
                if !isAirborne {
                    triggerEnd(success: false)
                    return
                }
            } else if !isAirborne {
                // Низкий шип: без прыжка — удар.
                triggerEnd(success: false)
                return
            }
        }

        for index in stars.indices where !stars[index].collected {
            let star = stars[index]
            let starRect = CGRect(
                x: layout.laneX(star.lane) - 14,
                y: star.y,
                width: 28,
                height: 28
            )
            if playerRect.intersects(starRect) {
                stars[index].collected = true
                bonusScore += 10
                HapticService.success()
                SoundService.playSuccess()
            }
        }
    }
}

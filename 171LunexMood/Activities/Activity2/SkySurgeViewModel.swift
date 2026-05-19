import Combine
import Foundation
import SwiftUI

struct SurgeObstacle: Identifiable {
    let id = UUID()
    var lane: Int
    var y: CGFloat
}

struct SurgeStar: Identifiable {
    let id = UUID()
    let order: Int
    var lane: Int
    var y: CGFloat
    var collected = false
}

@MainActor
final class SkySurgeViewModel: ObservableObject {
    @Published var playerLane = 1
    @Published var score = 0
    @Published var obstacles: [SurgeObstacle] = []
    @Published var stars: [SurgeStar] = []
    @Published var nextStarOrder = 0
    @Published var isGameOver = false
    @Published var showResult = false
    @Published var earnedStars = 0
    @Published var sessionSuccess = false
    @Published var newAchievements: [Achievement] = []
    @Published var starsDelta = 0
    @Published var layout = GameLaneLayout(width: 390, height: 844)
    @Published var statusMessage = "Swipe left/right to change lanes"
    @Published var isPaused = false

    let difficulty: Difficulty
    let level: Int
    let activityId = "sky_surge"
    var isPractice = false

    private var timer: AnyCancellable?
    private let playTime = PlayTimeTracker()
    private var tickCount = 0
    private let starsToCollect = 5

    private var fallSpeed: CGFloat {
        let mult: CGFloat
        switch difficulty {
        case .easy: mult = 2.4
        case .normal: mult = 3.2
        case .hard: mult = 4.0
        }
        return mult + CGFloat(level) * 0.2
    }

    init(difficulty: Difficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
    }

    func start(layout: GameLaneLayout) {
        self.layout = layout
        reset()
        playTime.reset()
        placeInitialStars()
        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    func togglePause() {
        guard !isGameOver else { return }
        if isPaused {
            isPaused = false
            playTime.endPause()
            timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.tick() }
        } else {
            isPaused = true
            playTime.beginPause()
            stop()
        }
    }

    func setLane(_ lane: Int) {
        guard !isGameOver, !isPaused else { return }
        let clamped = min(2, max(0, lane))
        guard clamped != playerLane else { return }
        playerLane = clamped
        HapticService.lightTap()
    }

    func shiftLane(_ direction: Int) {
        setLane(playerLane + direction)
    }

    func starsForScore(_ value: Int) -> Int {
        if value >= 250 { return 3 }
        if value >= 150 { return 2 }
        if value >= 50 { return 1 }
        return 0
    }

    func triggerEnd(success: Bool) {
        guard !isGameOver else { return }
        isGameOver = true
        stop()
        sessionSuccess = success
        statusMessage = success ? "All stars collected!" : "Crashed"
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
        score = 0
        obstacles = []
        stars = []
        nextStarOrder = 0
        isGameOver = false
        showResult = false
        isPaused = false
        tickCount = 0
        statusMessage = "Swipe left/right • Collect stars in order"
    }

    private func placeInitialStars() {
        let lanes = [1, 0, 2, 1, 0]
        for order in 0..<starsToCollect {
            stars.append(
                SurgeStar(
                    order: order,
                    lane: lanes[order],
                    y: layout.spawnY - CGFloat(order) * 160 - 80
                )
            )
        }
    }

    private func tick() {
        guard !isGameOver, !isPaused else { return }
        tickCount += 1

        for index in obstacles.indices {
            obstacles[index].y += fallSpeed
        }
        obstacles.removeAll { $0.y > layout.despawnY }

        for index in stars.indices where !stars[index].collected {
            stars[index].y += fallSpeed
        }

        // Новые препятствия — не в полосе следующей звезды.
        if tickCount % 75 == 0 {
            let safeLane = nextTargetStar?.lane
            var lane = tickCount % 3
            if lane == safeLane {
                lane = (lane + 1) % 3
            }
            obstacles.append(SurgeObstacle(lane: lane, y: layout.spawnY))
        }

        score = min(400, score + 1)
        checkInteractions()

        if nextStarOrder >= starsToCollect {
            triggerEnd(success: true)
        }
    }

    private var nextTargetStar: SurgeStar? {
        stars.first { $0.order == nextStarOrder && !$0.collected }
    }

    private func checkInteractions() {
        let playerRect = CGRect(
            x: layout.laneX(playerLane) - layout.playerSize / 2,
            y: layout.playerY - layout.playerSize / 2,
            width: layout.playerSize,
            height: layout.playerSize
        )

        for obstacle in obstacles {
            let rect = CGRect(
                x: layout.laneX(obstacle.lane) - 22,
                y: obstacle.y,
                width: 44,
                height: 44
            )
            if playerRect.intersects(rect) {
                triggerEnd(success: false)
                return
            }
        }

        guard let target = nextTargetStar else { return }
        let starRect = CGRect(
            x: layout.laneX(target.lane) - 16,
            y: target.y,
            width: 32,
            height: 32
        )

        if playerRect.intersects(starRect) {
            if let index = stars.firstIndex(where: { $0.id == target.id }) {
                stars[index].collected = true
                nextStarOrder += 1
                score += 25
                statusMessage = "Star \(nextStarOrder)/\(starsToCollect)"
                HapticService.success()
                SoundService.playSuccess()
            }
        } else if target.y > layout.playerY + 50, target.order == nextStarOrder {
            triggerEnd(success: false)
            statusMessage = "Missed a star"
        }
    }
}

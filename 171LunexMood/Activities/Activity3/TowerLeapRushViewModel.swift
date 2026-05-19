import Combine
import Foundation
import SwiftUI

struct LeapStep: Identifiable {
    let id = UUID()
    let index: Int
    let obstacleLane: Int?
    /// Идеальный заряд 0...1
    let sweetSpot: CGFloat
}

@MainActor
final class TowerLeapRushViewModel: ObservableObject {
    @Published var playerLane = 1
    @Published var chargeAmount: CGFloat = 0
    @Published var isCharging = false
    @Published var isJumping = false
    @Published var jumpsCompleted = 0
    @Published var accuracySamples: [Double] = []
    @Published var isGameOver = false
    @Published var showResult = false
    @Published var earnedStars = 0
    @Published var sessionSuccess = false
    @Published var newAchievements: [Achievement] = []
    @Published var starsDelta = 0
    @Published var layout = GameLaneLayout(width: 390, height: 844)
    @Published var statusMessage = "Hold screen to charge, release to jump"
    @Published var isPaused = false
    @Published private(set) var isRunning = false

    let difficulty: Difficulty
    let level: Int
    let activityId = "tower_leap_rush"
    var isPractice = false

    private var timer: AnyCancellable?
    private let playTime = PlayTimeTracker()
    private var steps: [LeapStep] = []
    private var currentStepIndex = 0
    private let jumpsToWin = 8

    init(difficulty: Difficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
    }

    var averageAccuracy: Double {
        guard !accuracySamples.isEmpty else { return 0 }
        return accuracySamples.reduce(0, +) / Double(accuracySamples.count)
    }

    var currentStep: LeapStep? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    func start(layout: GameLaneLayout) {
        guard layout.width > 50, layout.height > 50 else { return }
        stop()
        self.layout = layout
        reset()
        isRunning = true
        playTime.reset()
        timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        isCharging = false
    }

    func togglePause() {
        guard isRunning, !isGameOver else { return }
        if isPaused {
            isPaused = false
            playTime.endPause()
            timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in self?.tick() }
        } else {
            isPaused = true
            playTime.beginPause()
            isCharging = false
            stop()
            isRunning = true
        }
    }

    func beginCharge() {
        guard isRunning, !isGameOver, !isJumping, !isPaused else { return }
        isCharging = true
        HapticService.lightTap()
        statusMessage = "Release to jump!"
    }

    func endCharge() {
        guard isRunning, !isGameOver, !isJumping else { return }
        isCharging = false
        if chargeAmount < 0.12 {
            chargeAmount = 0.35
        }
        performJump()
    }

    func shiftLane(_ direction: Int) {
        guard isRunning, !isJumping, !isPaused else { return }
        let next = min(2, max(0, playerLane + direction))
        guard next != playerLane else { return }
        playerLane = next
        HapticService.lightTap()
        if let obstacle = currentStep?.obstacleLane {
            statusMessage = obstacle == next ? "Danger lane!" : "Safe lane"
        }
    }

    func starsForAccuracy(_ accuracy: Double) -> Int {
        if accuracy >= 0.95 { return 3 }
        if accuracy >= 0.85 { return 2 }
        if accuracy >= 0.70 { return 1 }
        return 0
    }

    func triggerEnd(success: Bool) {
        guard !isGameOver else { return }
        sessionSuccess = success
        isGameOver = true
        stop()
        statusMessage = success ? "Tower cleared!" : "Failed"
    }

    func completeSession(store: GameProgressStore) {
        guard !showResult else { return }
        earnedStars = sessionSuccess ? starsForAccuracy(averageAccuracy) : 0
        let accuracyPercent = Int(averageAccuracy * 100)
        let payload = store.recordLevelResult(
            activityId: activityId,
            difficulty: difficulty,
            level: level,
            stars: earnedStars,
            metricScore: accuracyPercent,
            playSeconds: playTime.activeSeconds,
            isPractice: isPractice
        )
        starsDelta = payload.starsDelta
        newAchievements = payload.newAchievements
        showResult = true
    }

    private func reset() {
        playerLane = 1
        chargeAmount = 0
        isCharging = false
        isJumping = false
        jumpsCompleted = 0
        accuracySamples = []
        isGameOver = false
        showResult = false
        isPaused = false
        currentStepIndex = 0
        steps = generateSteps()
        statusMessage = "Hold screen to charge, release to jump"
    }

    private func generateSteps() -> [LeapStep] {
        (0..<jumpsToWin).map { index in
            let obstacleLane: Int?
            if index < 2 {
                obstacleLane = nil
            } else {
                switch index % 3 {
                case 0: obstacleLane = 0
                case 1: obstacleLane = 2
                default: obstacleLane = nil
                }
            }
            return LeapStep(index: index, obstacleLane: obstacleLane, sweetSpot: 0.55)
        }
    }

    private func tick() {
        guard isRunning, !isGameOver, !isPaused, isCharging, !isJumping else { return }
        chargeAmount = min(1, chargeAmount + 0.022)
    }

    private func performJump() {
        guard let step = currentStep else { return }
        isJumping = true
        HapticService.mediumImpact()

        let accuracy = max(0, 1 - abs(Double(chargeAmount - step.sweetSpot)) / 0.45)
        accuracySamples.append(min(1, accuracy))

        let hitObstacle = step.obstacleLane.map { $0 == playerLane } ?? false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            self.isJumping = false
            self.chargeAmount = 0

            if hitObstacle {
                self.triggerEnd(success: false)
                return
            }

            self.jumpsCompleted += 1
            self.currentStepIndex += 1
            SoundService.playSuccess()
            HapticService.success()

            if self.jumpsCompleted >= self.jumpsToWin {
                self.triggerEnd(success: true)
            } else {
                self.statusMessage = "Jump \(self.jumpsCompleted)/\(self.jumpsToWin) • Swipe lane, hold to charge"
            }
        }
    }
}

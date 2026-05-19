import Foundation

@MainActor
final class PlayTimeTracker {
    private var sessionStart = Date()
    private var accumulatedPause: TimeInterval = 0
    private var pauseBegan: Date?

    func beginPause() {
        guard pauseBegan == nil else { return }
        pauseBegan = Date()
    }

    func endPause() {
        guard let began = pauseBegan else { return }
        accumulatedPause += Date().timeIntervalSince(began)
        pauseBegan = nil
    }

    func reset() {
        sessionStart = Date()
        accumulatedPause = 0
        pauseBegan = nil
    }

    var activeSeconds: Int {
        var total = Date().timeIntervalSince(sessionStart) - accumulatedPause
        if let began = pauseBegan {
            total -= Date().timeIntervalSince(began)
        }
        return max(1, Int(total))
    }
}

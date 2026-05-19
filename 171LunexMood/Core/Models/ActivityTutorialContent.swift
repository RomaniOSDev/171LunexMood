import Foundation

struct ActivityTutorialPage: Identifiable {
    let id = UUID()
    let headline: String
    let body: String
}

enum ActivityTutorialContent {
    static func pages(for activityId: String) -> [ActivityTutorialPage] {
        switch activityId {
        case "skybound_stride":
            return [
                ActivityTutorialPage(headline: "Tap To Jump", body: "Tap to jump over low spikes on the ground. You must be in the air when a spike reaches you."),
                ActivityTutorialPage(headline: "Double-Tap For Tall Spikes", body: "Tall spikes need a double-tap (long jump). Stay on the ground under a tall spike and you will fail."),
                ActivityTutorialPage(headline: "Reach The Goal", body: "Swipe to change lanes. Survive until the height bar fills — middle lane is often safest at the start.")
            ]
        case "sky_surge":
            return [
                ActivityTutorialPage(headline: "Swipe To Move", body: "Swipe or drag to switch lanes at the bottom."),
                ActivityTutorialPage(headline: "Stars In Order", body: "Collect glowing stars in the numbered order."),
                ActivityTutorialPage(headline: "Avoid Blocks", body: "Hitting a block ends the run. Missed stars count as a fail.")
            ]
        case "tower_leap_rush":
            return [
                ActivityTutorialPage(headline: "Hold To Charge", body: "Press and hold anywhere to fill the charge meter."),
                ActivityTutorialPage(headline: "Release To Leap", body: "Release to jump. Aim near the marker on the meter."),
                ActivityTutorialPage(headline: "Safe Lanes", body: "Move to a lane without ! before you release.")
            ]
        case "star_sprint":
            return [
                ActivityTutorialPage(headline: "30 Second Sprint", body: "Collect as many STARS ⭐ as you can before time runs out."),
                ActivityTutorialPage(headline: "Swipe Lanes", body: "Swipe left or right to reach stars in other lanes."),
                ActivityTutorialPage(headline: "Beat Your Best", body: "Higher counts earn more level stars when not in practice.")
            ]
        default:
            return [
                ActivityTutorialPage(headline: "Get Ready", body: "Complete the objective to earn STARS ⭐."),
                ActivityTutorialPage(headline: "Stay Focused", body: "Use quick reactions to avoid failures."),
                ActivityTutorialPage(headline: "Climb Higher", body: "Replay levels to improve your rating.")
            ]
        }
    }
}

enum DifficultyHint {
    static func text(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: return "Slower pace, more time between obstacles."
        case .normal: return "Balanced speed and spacing."
        case .hard: return "Fast obstacles, tight timing required."
        }
    }
}

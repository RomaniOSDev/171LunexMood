import UIKit

enum HapticService {
    static func lightTap() {
        guard GameProgressStore.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumImpact() {
        guard GameProgressStore.shared.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        guard GameProgressStore.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard GameProgressStore.shared.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

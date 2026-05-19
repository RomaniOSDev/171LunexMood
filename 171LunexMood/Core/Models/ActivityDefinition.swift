import Foundation

struct ActivityDefinition: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let metricLabel: String

    static let all: [ActivityDefinition] = [
        ActivityDefinition(
            id: "skybound_stride",
            title: "Skybound Stride",
            subtitle: "Tap to jump, swipe to switch lanes",
            iconName: "figure.climbing",
            metricLabel: "Height"
        ),
        ActivityDefinition(
            id: "sky_surge",
            title: "Sky Surge",
            subtitle: "Swipe lanes and collect stars in order",
            iconName: "wind",
            metricLabel: "Score"
        ),
        ActivityDefinition(
            id: "tower_leap_rush",
            title: "Tower Leap Rush",
            subtitle: "Hold to charge, release to leap",
            iconName: "arrow.up.circle.fill",
            metricLabel: "Accuracy"
        ),
        ActivityDefinition(
            id: "star_sprint",
            title: "Star Sprint",
            subtitle: "Collect STARS ⭐ before time runs out",
            iconName: "timer",
            metricLabel: "STARS"
        )
    ]

    static func find(id: String) -> ActivityDefinition? {
        all.first { $0.id == id }
    }
}

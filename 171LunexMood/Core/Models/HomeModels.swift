import Foundation

struct SuggestedPlay: Hashable {
    let activityId: String
    let difficulty: Difficulty
    let level: Int

    var activity: ActivityDefinition? {
        ActivityDefinition.find(id: activityId)
    }

    var label: String {
        let name = activity?.title ?? "Activity"
        return "\(name) · \(difficulty.title) · L\(level + 1)"
    }
}

enum HomeRoute: Hashable {
    case allGames
    case activity(String)
    case play(SuggestedPlay)
}

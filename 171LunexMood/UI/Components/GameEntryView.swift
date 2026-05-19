import SwiftUI

struct GameEntryView: View {
    let context: GameSessionContext
    @EnvironmentObject private var store: GameProgressStore
    @State private var showTutorial = false
    @State private var readyToPlay = false

    var body: some View {
        Group {
            if readyToPlay {
                gameView(for: context)
            } else {
                ZStack {
                    AppBackgroundView()
                    ProgressView()
                        .tint(.appAccent)
                }
            }
        }
        .onAppear {
            if store.hasSeenTutorial(activityId: context.activityId) {
                readyToPlay = true
            } else {
                showTutorial = true
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            ActivityTutorialView(activityId: context.activityId) {
                store.markTutorialSeen(activityId: context.activityId)
                showTutorial = false
                readyToPlay = true
            }
        }
    }

    @ViewBuilder
    private func gameView(for context: GameSessionContext) -> some View {
        switch context.activityId {
        case "skybound_stride":
            SkyboundStrideView(
                difficulty: context.difficulty,
                level: context.level,
                isPractice: context.isPractice
            )
        case "sky_surge":
            SkySurgeView(
                difficulty: context.difficulty,
                level: context.level,
                isPractice: context.isPractice
            )
        case "tower_leap_rush":
            TowerLeapRushView(
                difficulty: context.difficulty,
                level: context.level,
                isPractice: context.isPractice
            )
        case "star_sprint":
            StarSprintView(
                difficulty: context.difficulty,
                level: context.level,
                isPractice: context.isPractice
            )
        default:
            Text("Unavailable")
                .foregroundColor(.appTextPrimary)
        }
    }
}

import SwiftUI

struct StarSprintView: View {
    let difficulty: Difficulty
    let level: Int
    let isPractice: Bool

    @StateObject private var viewModel: StarSprintViewModel
    @EnvironmentObject private var progressStore: GameProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var didStart = false

    init(difficulty: Difficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
        _viewModel = StateObject(
            wrappedValue: StarSprintViewModel(difficulty: difficulty, level: level, isPractice: isPractice)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let safeWidth = max(geo.size.width, 1)
            let safeHeight = max(geo.size.height, 1)
            let layout = GameLaneLayout(width: safeWidth, height: safeHeight)

            ZStack {
                AppBackgroundView()

                if safeWidth > 50, safeHeight > 50 {
                    laneGuides(layout: layout, height: safeHeight)

                    ForEach(viewModel.fallingStars.filter { !$0.collected }) { star in
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.appAccent)
                            .position(x: layout.laneX(star.lane), y: star.y)
                    }

                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: layout.playerSize, height: layout.playerSize)
                        .overlay(Circle().stroke(Color.appAccent, lineWidth: 2))
                        .position(x: layout.laneX(viewModel.playerLane), y: layout.playerY)
                        .animation(.easeOut(duration: 0.1), value: viewModel.playerLane)
                }

                hud
            }
            .frame(width: safeWidth, height: safeHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        if value.translation.width < -24 {
                            viewModel.shiftLane(-1)
                        } else if value.translation.width > 24 {
                            viewModel.shiftLane(1)
                        }
                    }
            )
            .onChange(of: geo.size) { size in
                guard !didStart, size.width > 50, size.height > 50 else { return }
                didStart = true
                viewModel.startGame(layout: GameLaneLayout(width: size.width, height: size.height))
            }
            .onDisappear {
                didStart = false
                viewModel.stopGame()
            }
            .onChange(of: viewModel.isGameOver) { ended in
                if ended, !viewModel.showResult {
                    viewModel.completeSession(store: progressStore)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func laneGuides(layout: GameLaneLayout, height: CGFloat) -> some View {
        Canvas { context, size in
            for lane in 0..<3 {
                let x = layout.laneX(lane)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    path,
                    with: .color(.appSurface.opacity(0.45)),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 8])
                )
            }
        }
        .frame(height: height)
    }

    @ViewBuilder
    private var hud: some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if isPractice {
                        Text("PRACTICE")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.appAccent)
                    }
                    Text("STARS: \(viewModel.starsCollected)")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text(String(format: "Time: %.0fs", max(0, viewModel.timeRemaining)))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    Text(viewModel.statusMessage)
                        .font(.caption2)
                        .foregroundColor(.appAccent)
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    viewModel.togglePause()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 44, height: 44)
                }
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding()

            Spacer()
        }

        if viewModel.isPaused {
            GamePauseOverlay(isPractice: isPractice, onResume: {
                viewModel.togglePause()
            }, onQuit: {
                viewModel.stopGame()
                dismiss()
            })
        }

        if viewModel.showResult {
            GameResultOverlay(
                success: viewModel.sessionSuccess,
                stars: viewModel.earnedStars,
                starsDelta: viewModel.starsDelta,
                isPractice: isPractice,
                metricTitle: "STARS Collected",
                metricValue: "\(viewModel.starsCollected)",
                hasNextLevel: level + 1 < Difficulty.levelCount,
                newAchievements: viewModel.newAchievements,
                onRetry: {
                    viewModel.showResult = false
                    viewModel.isGameOver = false
                    didStart = true
                    viewModel.startGame(layout: viewModel.layout)
                },
                onBack: { dismiss() },
                onNextLevel: { dismiss() }
            )
        }
    }
}

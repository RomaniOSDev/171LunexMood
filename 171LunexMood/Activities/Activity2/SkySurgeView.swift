import SwiftUI

struct SkySurgeView: View {
    let difficulty: Difficulty
    let level: Int
    let isPractice: Bool

    @StateObject private var viewModel: SkySurgeViewModel
    @EnvironmentObject private var progressStore: GameProgressStore
    @Environment(\.dismiss) private var dismiss

    init(difficulty: Difficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
        _viewModel = StateObject(
            wrappedValue: SkySurgeViewModel(difficulty: difficulty, level: level, isPractice: isPractice)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let layout = GameLaneLayout(width: geo.size.width, height: geo.size.height)

            ZStack {
                AppBackgroundView()

                Canvas { context, size in
                    for lane in 0..<3 {
                        let x = layout.laneX(lane)
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(path, with: .color(.appSurface.opacity(0.45)), style: StrokeStyle(lineWidth: 2, dash: [6, 8]))
                    }
                }

                ForEach(viewModel.obstacles) { obstacle in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.appAccent)
                        .frame(width: 44, height: 44)
                        .position(x: layout.laneX(obstacle.lane), y: obstacle.y + 22)
                }

                ForEach(viewModel.stars) { star in
                    if !star.collected {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(star.order == viewModel.nextStarOrder ? .appAccent : .appTextSecondary.opacity(0.5))
                            .overlay(
                                Text("\(star.order + 1)")
                                    .font(.caption2.bold())
                                    .foregroundColor(.appTextPrimary)
                            )
                            .position(x: layout.laneX(star.lane), y: star.y)
                    }
                }

                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: layout.playerSize, height: layout.playerSize)
                    .overlay(Circle().stroke(Color.appAccent, lineWidth: 2))
                    .position(x: layout.laneX(viewModel.playerLane), y: layout.playerY)
                    .animation(.easeOut(duration: 0.1), value: viewModel.playerLane)

                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if isPractice {
                                Text("PRACTICE")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.appAccent)
                            }
                            Text("Score: \(viewModel.score)")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                            Text("Stars: \(viewModel.nextStarOrder)/5")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                            Text(viewModel.statusMessage)
                                .font(.caption2)
                                .foregroundColor(.appAccent)
                        }
                        Spacer()
                        Button { viewModel.togglePause() } label: {
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
                        viewModel.stop()
                        dismiss()
                    })
                }

                if viewModel.showResult {
                    GameResultOverlay(
                        success: viewModel.sessionSuccess,
                        stars: viewModel.earnedStars,
                        starsDelta: viewModel.starsDelta,
                        isPractice: isPractice,
                        metricTitle: "Score",
                        metricValue: "\(viewModel.score)",
                        hasNextLevel: level + 1 < Difficulty.levelCount,
                        newAchievements: viewModel.newAchievements,
                        onRetry: {
                            viewModel.showResult = false
                            viewModel.isGameOver = false
                            viewModel.start(layout: layout)
                        },
                        onBack: { dismiss() },
                        onNextLevel: { dismiss() }
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.width < -30 {
                            viewModel.shiftLane(-1)
                        } else if value.translation.width > 30 {
                            viewModel.shiftLane(1)
                        }
                    }
            )
            .onTapGesture { location in
                let lane = layout.laneIndex(for: location.x)
                viewModel.setLane(lane)
            }
            .onAppear { viewModel.start(layout: layout) }
            .onDisappear { viewModel.stop() }
            .onChange(of: viewModel.isGameOver) { ended in
                if ended, !viewModel.showResult {
                    viewModel.completeSession(store: progressStore)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

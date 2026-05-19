import SwiftUI

struct SkyboundStrideView: View {
    let difficulty: Difficulty
    let level: Int
    let isPractice: Bool

    @StateObject private var viewModel: SkyboundStrideViewModel
    @EnvironmentObject private var progressStore: GameProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var didStart = false

    init(difficulty: Difficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
        _viewModel = StateObject(
            wrappedValue: SkyboundStrideViewModel(difficulty: difficulty, level: level, isPractice: isPractice)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let safeWidth = max(geo.size.width, 1)
            let safeHeight = max(geo.size.height, 1)
            let layout = GameLaneLayout(width: safeWidth, height: safeHeight)
            let platformWidth = max(safeWidth - 48, 100)

            ZStack {
                AppBackgroundView()

                if safeWidth > 50, safeHeight > 50 {
                    Canvas { context, size in
                        let canvasWidth = max(size.width, 1)
                        let canvasHeight = max(size.height, 1)
                        for lane in 0..<3 {
                            let x = layout.laneX(lane)
                            var path = Path()
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: canvasHeight))
                            context.stroke(
                                path,
                                with: .color(.appSurface.opacity(0.45)),
                                style: StrokeStyle(lineWidth: 2, dash: [6, 8])
                            )
                        }
                        let groundY = layout.playerY + 28
                        let groundWidth = max(canvasWidth - 32, 1)
                        let ground = CGRect(x: 16, y: groundY, width: groundWidth, height: 10)
                        context.fill(Path(roundedRect: ground, cornerRadius: 4), with: .color(.appSurface))
                    }

                    ForEach(0..<6, id: \.self) { row in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.appSurface.opacity(0.5))
                            .frame(width: platformWidth, height: 8)
                            .position(
                                x: safeWidth / 2,
                                y: max(layout.playerY - CGFloat(row) * 55 - 20, 40)
                            )
                    }

                    ForEach(viewModel.obstacles) { obstacle in
                        spikeView(high: obstacle.isHigh)
                            .position(
                                x: layout.laneX(obstacle.lane),
                                y: obstacle.y + (obstacle.isHigh ? 22 : 14)
                            )
                    }

                    ForEach(viewModel.stars.filter { !$0.collected }) { star in
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundColor(.appAccent)
                            .position(x: layout.laneX(star.lane), y: star.y)
                    }

                    ZStack {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: layout.playerSize, height: layout.playerSize)
                        if viewModel.isAirborne {
                            Circle()
                                .stroke(Color.appAccent, lineWidth: 3)
                                .frame(width: layout.playerSize + 12, height: layout.playerSize + 12)
                                .opacity(0.8)
                        }
                    }
                    .position(x: layout.laneX(viewModel.playerLane), y: layout.playerY)
                    .animation(.easeOut(duration: 0.12), value: viewModel.playerLane)
                }

                hud(layout: layout)
            }
            .frame(width: safeWidth, height: safeHeight)
            .contentShape(Rectangle())
            .onTapGesture { viewModel.handleTap() }
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

    @ViewBuilder
    private func hud(layout: GameLaneLayout) -> some View {
        let goal = viewModel.goalScore
        let progress = goal > 0 ? min(1, Double(viewModel.score) / Double(goal)) : 0

        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if isPractice {
                        Text("PRACTICE")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.appAccent)
                    }
                    Text("Height: \(viewModel.score) / \(goal)")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    GradientProgressBar(progress: progress, height: 8)
                        .frame(maxWidth: 180)
                    Text(viewModel.statusMessage)
                        .font(.caption2)
                        .foregroundColor(.appAccent)
                        .lineLimit(2)
                    Text("Tap = jump · Double-tap = high jump · Swipe = lane")
                        .font(.system(size: 10))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
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

            if viewModel.isAirborne {
                Text("AIRBORNE")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.appAccent)
                    .padding(.bottom, max(layout.height * 0.1, 20))
            }
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
                metricTitle: "Height Reached",
                metricValue: "\(viewModel.score)",
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

    private func spikeView(high: Bool) -> some View {
        let h = high ? 44.0 : 28.0
        return Path { path in
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: 18, y: 0))
            path.addLine(to: CGPoint(x: 36, y: h))
            path.closeSubpath()
        }
        .fill(Color.appAccent)
        .frame(width: 36, height: h)
    }
}

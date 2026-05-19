import SwiftUI

struct TowerLeapRushView: View {
    let difficulty: Difficulty
    let level: Int
    let isPractice: Bool

    @StateObject private var viewModel: TowerLeapRushViewModel
    @EnvironmentObject private var progressStore: GameProgressStore
    @Environment(\.dismiss) private var dismiss
    @State private var jumpOffset: CGFloat = 0
    @State private var didStart = false
    @State private var pressStartLane = 1

    init(difficulty: Difficulty, level: Int, isPractice: Bool = false) {
        self.difficulty = difficulty
        self.level = level
        self.isPractice = isPractice
        _viewModel = StateObject(
            wrappedValue: TowerLeapRushViewModel(difficulty: difficulty, level: level, isPractice: isPractice)
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
                    ForEach(0..<3, id: \.self) { lane in
                        let x = layout.laneX(lane)
                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: safeHeight))
                        }
                        .stroke(Color.appSurface.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    }

                    platformBar(width: platformWidth, centerX: safeWidth / 2, y: layout.playerY + 22)

                    if let step = viewModel.currentStep {
                        platformBar(width: platformWidth * 0.9, centerX: safeWidth / 2, y: layout.playerY - 100)

                        if let obstacleLane = step.obstacleLane {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.appAccent)
                                .frame(width: 50, height: 36)
                                .position(x: layout.laneX(obstacleLane), y: layout.playerY - 118)
                        }

                        laneHint(layout: layout, obstacleLane: step.obstacleLane)
                    }

                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: layout.playerSize, height: layout.playerSize)
                        .overlay(Circle().stroke(Color.appAccent, lineWidth: 2))
                        .offset(y: jumpOffset)
                        .position(x: layout.laneX(viewModel.playerLane), y: layout.playerY)
                        .animation(.easeOut(duration: 0.12), value: viewModel.playerLane)

                    chargeMeter(sweetSpot: viewModel.currentStep?.sweetSpot ?? 0.55)
                        .position(x: 36, y: safeHeight * 0.42)
                }

                hud(safeHeight: safeHeight)

                if viewModel.showResult {
                    resultOverlay(layout: layout)
                }
            }
            .frame(width: safeWidth, height: safeHeight)
            .contentShape(Rectangle())
            .gesture(dragControl)
            .onChange(of: geo.size) { size in
                guard !didStart, size.width > 50, size.height > 50 else { return }
                didStart = true
                viewModel.start(layout: GameLaneLayout(width: size.width, height: size.height))
            }
            .onDisappear {
                didStart = false
                viewModel.stop()
            }
            .onChange(of: viewModel.isGameOver) { ended in
                if ended, !viewModel.showResult {
                    viewModel.completeSession(store: progressStore)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var dragControl: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !viewModel.isCharging, !viewModel.isJumping {
                    pressStartLane = viewModel.playerLane
                    viewModel.beginCharge()
                }
                let laneDelta = Int((value.translation.width / 70).rounded())
                let targetLane = min(2, max(0, pressStartLane + laneDelta))
                if targetLane != viewModel.playerLane {
                    viewModel.playerLane = targetLane
                }
            }
            .onEnded { value in
                if abs(value.translation.width) > 50 {
                    viewModel.shiftLane(value.translation.width > 0 ? 1 : -1)
                }
                viewModel.endCharge()
                animateJump()
            }
    }

    @ViewBuilder
    private func laneHint(layout: GameLaneLayout, obstacleLane: Int?) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { lane in
                let isDanger = obstacleLane == lane
                Text(isDanger ? "!" : "✓")
                    .font(.caption.bold())
                    .foregroundColor(isDanger ? .appAccent : .appTextSecondary.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .position(x: layout.width / 2, y: layout.playerY - 155)
    }

    private func chargeMeter(sweetSpot: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.appSurface)
                .frame(width: 24, height: 160)
            Rectangle()
                .fill(Color.appTextSecondary.opacity(0.6))
                .frame(width: 24, height: 3)
                .offset(y: -(160 * sweetSpot - 1.5))
            RoundedRectangle(cornerRadius: 8)
                .fill(viewModel.isCharging ? Color.appAccent : Color.appPrimary.opacity(0.5))
                .frame(width: 24, height: max(6, 160 * viewModel.chargeAmount))
        }
    }

    @ViewBuilder
    private func hud(safeHeight: CGFloat) -> some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if isPractice {
                        Text("PRACTICE")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.appAccent)
                    }
                    Text("Jumps: \(viewModel.jumpsCompleted)/8")
                        .font(.headline)
                        .foregroundColor(.appTextPrimary)
                    Text("Accuracy: \(Int(viewModel.averageAccuracy * 100))%")
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                    Text(viewModel.statusMessage)
                        .font(.caption2)
                        .foregroundColor(.appAccent)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
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

            if viewModel.isPaused {
                GamePauseOverlay(isPractice: isPractice, onResume: {
                    viewModel.togglePause()
                }, onQuit: {
                    viewModel.stop()
                    dismiss()
                })
            }

            if viewModel.isCharging {
                Text("RELEASE TO JUMP")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.appAccent)
                    .padding(.bottom, max(safeHeight * 0.12, 24))
            } else {
                Text("HOLD TO CHARGE")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.appTextSecondary)
                    .padding(.bottom, max(safeHeight * 0.12, 24))
            }
        }
    }

    @ViewBuilder
    private func resultOverlay(layout: GameLaneLayout) -> some View {
        GameResultOverlay(
            success: viewModel.sessionSuccess,
            stars: viewModel.earnedStars,
            starsDelta: viewModel.starsDelta,
            isPractice: isPractice,
            metricTitle: "Jump Accuracy",
            metricValue: "\(Int(viewModel.averageAccuracy * 100))%",
            hasNextLevel: level + 1 < Difficulty.levelCount,
            newAchievements: viewModel.newAchievements,
            onRetry: {
                viewModel.showResult = false
                viewModel.isGameOver = false
                didStart = true
                viewModel.start(layout: layout)
            },
            onBack: { dismiss() },
            onNextLevel: { dismiss() }
        )
    }

    private func platformBar(width: CGFloat, centerX: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.appSurface)
            .frame(width: width, height: 14)
            .position(x: centerX, y: y)
    }

    private func animateJump() {
        withAnimation(.easeOut(duration: 0.22)) {
            jumpOffset = -65
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeIn(duration: 0.18)) {
                jumpOffset = 0
            }
        }
    }
}

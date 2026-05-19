import SwiftUI

struct GamePauseOverlay: View {
    let isPractice: Bool
    let onResume: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            AppCard(accent: .appAccent, padding: 24) {
                VStack(spacing: 20) {
                    IconBadge(systemName: "pause.circle.fill", size: 56)
                    Text("Paused")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)

                    if isPractice {
                        Text("Practice mode — progress is not saved")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton(title: "Resume") {
                        onResume()
                    }

                    PrimaryButton(title: "Quit Level", style: .secondary) {
                        onQuit()
                    }
                }
                .frame(maxWidth: 320)
            }
            .padding(.horizontal, 28)
        }
    }
}

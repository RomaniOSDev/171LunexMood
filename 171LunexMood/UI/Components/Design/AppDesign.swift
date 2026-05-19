import SwiftUI

enum AppLayout {
    static let cardRadius: CGFloat = 18
    static let cellRadius: CGFloat = 16
    static let iconSize: CGFloat = 48
    static let horizontalPadding: CGFloat = 20
}

// MARK: - Card chrome

struct AppCard<Content: View>: View {
    var accent: Color = .appPrimary
    var padding: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .elevatedSurface(accent: accent, cornerRadius: AppLayout.cardRadius)
    }
}

struct IconBadge: View {
    let systemName: String
    var size: CGFloat = AppLayout.iconSize
    var accent: Color = .appAccent

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.4), Color.appPrimary.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                }
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appTextPrimary, accent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .shadow(color: accent.opacity(0.2), radius: 4, y: 2)
    }
}

struct ScreenHeader: View {
    let title: String
    var subtitle: String?
    var icon: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let icon {
                IconBadge(systemName: icon, size: 52)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(0.8)
                .foregroundColor(.appTextSecondary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.appAccent)
            }
        }
    }
}

struct GradientProgressBar: View {
    let progress: Double
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appBackground.opacity(0.55))
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    }
                Capsule()
                    .fill(AppGradients.progress)
                    .frame(width: max(height, geo.size.width * CGFloat(min(1, max(0, progress)))))
            }
        }
        .frame(height: height)
    }
}

struct DifficultySegmentedControl: View {
    @Binding var selection: Difficulty

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Difficulty.allCases) { difficulty in
                Button {
                    HapticService.lightTap()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = difficulty
                    }
                } label: {
                    Text(difficulty.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(selection == difficulty ? .appTextPrimary : .appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selection == difficulty {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppGradients.surfaceFill(accent: .appAccent))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                                    }
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .elevatedSurface(accent: .appPrimary, cornerRadius: 14, kind: .inset, showShadow: false)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? .appTextPrimary : .appTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(AppGradients.surfaceFill(accent: .appAccent))
                            .overlay {
                                Capsule().stroke(Color.appAccent.opacity(0.45), lineWidth: 1)
                            }
                    } else {
                        Capsule()
                            .fill(Color.appSurface.opacity(0.65))
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

extension GameProgressStore {
    func totalStarsInActivity(_ activityId: String) -> Int {
        starsPerActivity[activityId]?.values.flatMap { $0 }.reduce(0, +) ?? 0
    }

    var maxStarsPerActivity: Int {
        Difficulty.allCases.count * Difficulty.levelCount * 3
    }

    var unlockedAchievementCount: Int {
        Achievement.all.filter { $0.isUnlocked(self) }.count
    }
}

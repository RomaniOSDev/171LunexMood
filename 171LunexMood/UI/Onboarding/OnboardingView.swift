import SwiftUI

private struct OnboardingPageData: Identifiable {
    let id: Int
    let icon: String
    let headline: String
    let body: String
}

struct OnboardingView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var page = 0

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            id: 0,
            icon: "hand.tap.fill",
            headline: "Tap To Jump",
            body: "Tap for a short jump over low spikes. Double-tap for a long jump over tall spikes."
        ),
        OnboardingPageData(
            id: 1,
            icon: "star.fill",
            headline: "Collect STARS ⭐",
            body: "Clear levels to earn STARS. Fill the daily goal and unlock achievements as you climb."
        ),
        OnboardingPageData(
            id: 2,
            icon: "arrow.up.to.line.compact",
            headline: "Start The Climb",
            body: "Swipe to switch lanes, beat weekly challenges, and push your streak higher every day."
        )
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                onboardingHeader
                    .padding(.horizontal, AppLayout.horizontalPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                TabView(selection: $page) {
                    ForEach(pages) { pageData in
                        onboardingPage(pageData)
                            .tag(pageData.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .scrollContentBackground(.hidden)
                .animation(.easeInOut(duration: 0.28), value: page)

                pageIndicator
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                PrimaryButton(title: page < pages.count - 1 ? "Next" : "Get Started") {
                    if page < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            page += 1
                        }
                    } else {
                        HapticService.mediumImpact()
                        store.hasSeenOnboarding = true
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
                .padding(.bottom, 36)
            }
        }
    }

    private var onboardingHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            IconBadge(systemName: "sparkles", size: 48, accent: .appAccent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appTextSecondary)
                Text("Tower Climber")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.appTextPrimary)
            }
            Spacer()
            Text("\(page + 1)/\(pages.count)")
                .font(.caption.weight(.bold))
                .foregroundColor(.appAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .elevatedInset(accent: .appAccent, cornerRadius: 10)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Group {
                    if index == page {
                        Capsule().fill(AppGradients.progress)
                    } else {
                        Capsule().fill(Color.appTextSecondary.opacity(0.3))
                    }
                }
                .frame(width: index == page ? 28 : 8, height: 8)
                .animation(.spring(response: 0.38, dampingFraction: 0.78), value: page)
            }
        }
    }

    @ViewBuilder
    private func onboardingPage(_ data: OnboardingPageData) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                illustrationCard(for: data.id)
                    .padding(.horizontal, AppLayout.horizontalPadding)

                AppCard(accent: .appAccent) {
                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            Text("\(data.id + 1)")
                                .font(.caption.weight(.black))
                                .foregroundColor(.appAccent)
                                .frame(width: 28, height: 28)
                                .background(Color.appAccent.opacity(0.15))
                                .clipShape(Circle())

                            IconBadge(systemName: data.icon, size: 36, accent: .appAccent)

                            Spacer()
                        }

                        Text(data.headline)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(data.body)
                            .font(.body)
                            .foregroundColor(.appTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, AppLayout.horizontalPadding)
            }
            .padding(.bottom, 16)
        }
        .appScrollStyle()
    }

    @ViewBuilder
    private func illustrationCard(for index: Int) -> some View {
        ZStack {
            switch index {
            case 0:
                OnboardingJumpIllustration()
            case 1:
                OnboardingStarsIllustration()
            default:
                OnboardingTowerIllustration()
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .elevatedSurface(accent: .appAccent, cornerRadius: 22, kind: .hero)
    }
}

// MARK: - Illustrations

struct OnboardingJumpIllustration: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.appSurface.opacity(0.35))
                .frame(height: 12)
                .padding(.horizontal, 32)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 28)

            VStack {
                Spacer()
                HStack(spacing: 48) {
                    spike(low: true)
                    spike(low: false)
                }
                .padding(.bottom, 36)

                ZStack {
                    Circle()
                        .fill(AppGradients.buttonPrimary)
                        .frame(width: 44, height: 44)
                        .shadow(color: .appAccent.opacity(0.35), radius: 6, y: 3)
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(width: 44, height: 44)
                }
                .offset(y: appeared ? -72 : 0)
            }
            .padding(.bottom, 8)

            if appeared {
                Text("DOUBLE-TAP = HIGH JUMP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.appAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .elevatedInset(accent: .appAccent, cornerRadius: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 20)
            }
        }
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0.35)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }

    private func spike(low: Bool) -> some View {
        let h: CGFloat = low ? 28 : 44
        return Path { path in
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: 18, y: 0))
            path.addLine(to: CGPoint(x: 36, y: h))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [.appAccent, .appPrimary.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: 36, height: h)
    }
}

struct OnboardingStarsIllustration: View {
    @State private var appeared = false

    private let offsets: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-58, -36, 26), (52, -8, 30), (-18, 38, 24), (68, 24, 28), (0, -68, 34)
    ]

    var body: some View {
        ZStack {
            ForEach(0..<offsets.count, id: \.self) { index in
                let item = offsets[index]
                Image(systemName: "star.fill")
                    .font(.system(size: item.size, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appAccent, .appPrimary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .appAccent.opacity(appeared ? 0.4 : 0), radius: 8)
                    .offset(x: item.x, y: item.y)
                    .scaleEffect(appeared ? 1 : 0.35)
                    .opacity(appeared ? 1 : 0.15)
                    .animation(
                        .spring(response: 0.42, dampingFraction: 0.7)
                            .delay(Double(index) * 0.07),
                        value: appeared
                    )
            }

            if appeared {
                VStack(spacing: 4) {
                    Text("15")
                        .font(.title.weight(.bold))
                        .foregroundColor(.appAccent)
                    Text("daily goal")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.appTextSecondary)
                }
                .padding(12)
                .elevatedInset(accent: .appAccent, cornerRadius: 12)
            }
        }
        .onAppear {
            appeared = true
        }
    }
}

struct OnboardingTowerIllustration: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { level in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppGradients.surfaceFill(accent: .appPrimary))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.appPrimary.opacity(0.25), lineWidth: 0.5)
                    }
                    .frame(width: 128 - CGFloat(level) * 10, height: 16)
                    .offset(y: CGFloat(level) * 26 - 72)
                    .opacity(appeared ? 1 : 0.15)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.72)
                            .delay(Double(level) * 0.05),
                        value: appeared
                    )
            }

            ZStack {
                Circle()
                    .fill(AppGradients.buttonPrimary)
                    .frame(width: 32, height: 32)
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: 32, height: 32)
            }
            .offset(y: appeared ? -98 : 36)

            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.appAccent)
                Text("Build your streak")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .elevatedInset(accent: .appAccent, cornerRadius: 10)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 16)
            .opacity(appeared ? 1 : 0)
        }
        .scaleEffect(appeared ? 1 : 0.92)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                appeared = true
            }
        }
    }
}

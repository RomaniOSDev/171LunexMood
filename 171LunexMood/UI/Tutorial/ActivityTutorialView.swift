import SwiftUI

struct ActivityTutorialView: View {
    let activityId: String
    let onFinish: () -> Void

    @State private var pageIndex = 0

    private var pages: [ActivityTutorialPage] {
        ActivityTutorialContent.pages(for: activityId)
    }

    private var activity: ActivityDefinition? {
        ActivityDefinition.find(id: activityId)
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                HStack {
                    if let activity {
                        IconBadge(systemName: activity.iconName, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("How To Play")
                                .font(.headline)
                                .foregroundColor(.appTextPrimary)
                            Text(activity.title)
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        tutorialPage(page, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 340)

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == pageIndex ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                            .frame(width: index == pageIndex ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: pageIndex)
                    }
                }
                .padding(.bottom, 16)

                PrimaryButton(title: pageIndex < pages.count - 1 ? "Next" : "Start Playing") {
                    HapticService.lightTap()
                    if pageIndex < pages.count - 1 {
                        withAnimation { pageIndex += 1 }
                    } else {
                        onFinish()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func tutorialPage(_ page: ActivityTutorialPage, index: Int) -> some View {
        AppCard(accent: .appAccent) {
            VStack(spacing: 18) {
                Text("\(index + 1)")
                    .font(.caption.weight(.black))
                    .foregroundColor(.appAccent)
                    .frame(width: 28, height: 28)
                    .background(Color.appAccent.opacity(0.15))
                    .clipShape(Circle())

                Text(page.headline)
                    .font(.title3.bold())
                    .foregroundColor(.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(.horizontal, 24)
    }
}

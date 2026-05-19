import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var markdownText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ScreenHeader(
                            title: "Privacy Policy",
                            subtitle: "How we handle your data",
                            icon: "hand.raised.fill"
                        )

                        AppCard {
                            if let attributed = try? AttributedString(markdown: markdownText) {
                                Text(attributed)
                                    .foregroundColor(.appTextPrimary)
                                    .tint(.appAccent)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(markdownText)
                                    .foregroundColor(.appTextPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(AppLayout.horizontalPadding)
                    .padding(.bottom, 24)
                }
                .appScrollStyle()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        HapticService.lightTap()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.appAccent)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            markdownText = loadPrivacyMarkdown()
        }
    }

    private func loadPrivacyMarkdown() -> String {
        guard let url = Bundle.main.url(forResource: "privacy_policy", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "# Privacy Policy\n\nContent unavailable."
        }
        return text
    }
}

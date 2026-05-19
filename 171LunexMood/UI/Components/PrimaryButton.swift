import SwiftUI

struct PrimaryButton: View {
    let title: String
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary
        case destructive
        case secondary
    }

    var body: some View {
        Button {
            HapticService.lightTap()
            action()
        } label: {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .background { buttonBackground }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .modifier(ButtonDepthModifier(style: style))
    }

    @ViewBuilder
    private var buttonBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        switch style {
        case .primary:
            shape.fill(AppGradients.buttonPrimary)
                .overlay {
                    shape.stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                }
        case .destructive:
            shape.fill(
                LinearGradient(
                    colors: [Color.appPrimary.opacity(0.95), Color.appSurface.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .secondary:
            shape
                .fill(AppGradients.surfaceFill(accent: .appPrimary))
                .overlay {
                    shape.stroke(Color.appPrimary.opacity(0.35), lineWidth: 1)
                }
        }
    }
}

private struct ButtonDepthModifier: ViewModifier {
    let style: PrimaryButton.Style

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            AppDepth.apply(to: content)
        case .secondary:
            content.shadow(color: AppDepth.shadowColor.opacity(0.6), radius: 4, y: 2)
        case .destructive:
            AppDepth.apply(to: content)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

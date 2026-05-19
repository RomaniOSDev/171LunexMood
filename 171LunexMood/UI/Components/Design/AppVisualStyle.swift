import SwiftUI

/// Общие градиенты и тени — один стиль на все экраны, без лишних слоёв.
enum AppGradients {
    static let surfaceTop = Color.appSurface.opacity(0.98)
    static let surfaceBottom = Color.appSurface.opacity(0.82)

    static func surfaceFill(accent: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                surfaceTop,
                surfaceBottom,
                accent.opacity(0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func borderStroke(accent: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.14),
                accent.opacity(0.42),
                accent.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func heroFill(accent: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.appPrimary.opacity(0.9),
                accent.opacity(0.5),
                Color.appSurface.opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let buttonPrimary = LinearGradient(
        colors: [
            Color.appPrimary,
            Color.appPrimary.opacity(0.78),
            Color.appAccent.opacity(0.42)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let progress = LinearGradient(
        colors: [Color.appPrimary, Color.appAccent],
        startPoint: .leading,
        endPoint: .trailing
    )
}

/// Одна тень на элемент — так SwiftUI меньше перерисовывает.
enum AppDepth {
    static let shadowColor = Color.black.opacity(0.28)
    static let shadowRadius: CGFloat = 7
    static let shadowY: CGFloat = 4

    static func apply(to view: some View) -> some View {
        view.shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }
}

enum ElevatedKind {
    case card
    case inset
    case hero
}

struct ElevatedSurfaceModifier: ViewModifier {
    var accent: Color = .appPrimary
    var cornerRadius: CGFloat = AppLayout.cardRadius
    var kind: ElevatedKind = .card
    var showShadow: Bool = true

    func body(content: Content) -> some View {
        let shaped = content.background { surfaceBackground }
        if showShadow, kind != .inset {
            AppDepth.apply(to: shaped)
        } else {
            shaped
        }
    }

    @ViewBuilder
    private var surfaceBackground: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        switch kind {
        case .card, .inset:
            shape
                .fill(AppGradients.surfaceFill(accent: accent))
                .overlay {
                    shape.stroke(AppGradients.borderStroke(accent: accent), lineWidth: 1)
                }
        case .hero:
            shape
                .fill(AppGradients.heroFill(accent: accent))
                .overlay {
                    shape.stroke(accent.opacity(0.38), lineWidth: 1)
                }
        }
    }
}

extension View {
    /// Карточка с градиентом, обводкой и одной тенью.
    func elevatedSurface(
        accent: Color = .appPrimary,
        cornerRadius: CGFloat = AppLayout.cardRadius,
        kind: ElevatedKind = .card,
        showShadow: Bool = true
    ) -> some View {
        modifier(
            ElevatedSurfaceModifier(
                accent: accent,
                cornerRadius: cornerRadius,
                kind: kind,
                showShadow: showShadow
            )
        )
    }

    /// Вложенный блок внутри карточки (без тени).
    func elevatedInset(
        accent: Color = .appAccent,
        cornerRadius: CGFloat = 12
    ) -> some View {
        elevatedSurface(accent: accent, cornerRadius: cornerRadius, kind: .inset, showShadow: false)
    }
}

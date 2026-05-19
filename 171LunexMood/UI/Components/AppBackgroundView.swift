import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.background,
                    AppColors.surface.opacity(0.88),
                    SeasonalTheme.accentTint.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AmbientGlowLayer(tint: SeasonalTheme.accentTint)

            StaticDotPatternView(tint: SeasonalTheme.accentTint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

enum SeasonalTheme {
    static var accentTint: Color {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return Color.appAccent.opacity(0.9)
        case 3, 4, 5: return Color.appPrimary.opacity(0.85)
        case 6, 7, 8: return Color.appAccent
        default: return Color.appPrimary.opacity(0.7)
        }
    }
}

/// Статичные «орбы» — без blur и без анимации.
private struct AmbientGlowLayer: View {
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: w * 0.7, height: w * 0.7)
                    .offset(x: -w * 0.2, y: -h * 0.15)
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: w * 0.55, height: w * 0.55)
                    .offset(x: w * 0.25, y: h * 0.35)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Сетка точек без TimelineView — не нагружает CPU/GPU каждый кадр.
private struct StaticDotPatternView: View {
    let tint: Color
    private let rows = 7
    private let cols = 5

    var body: some View {
        Canvas { context, size in
            guard size.width > 1, size.height > 1 else { return }
            let dot = tint.opacity(0.09)
            for row in 0..<rows {
                for col in 0..<cols {
                    let x = (CGFloat(col) + 0.5) * (size.width / CGFloat(cols))
                    let y = (CGFloat(row) + 0.5) * (size.height / CGFloat(rows))
                    let rect = CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)
                    context.fill(Path(ellipseIn: rect), with: .color(dot))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

enum AppColors {
    static var background: Color {
        color(named: "AppBackground")
    }

    static var surface: Color {
        color(named: "AppSurface")
    }

    private static func color(named: String) -> Color {
        if let uiColor = UIColor(named: named, in: .main, compatibleWith: nil) {
            return Color(uiColor: uiColor)
        }
        return Color(named, bundle: .main)
    }
}

extension View {
    func withAppBackground() -> some View {
        ZStack {
            AppBackgroundView()
            self
        }
    }

    func appScrollStyle() -> some View {
        scrollContentBackground(.hidden)
    }

    func appNavigationStyle() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

import SwiftUI

struct StarRatingView: View {
    let count: Int
    var max: Int = 3
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(index < count ? .appAccent : .appTextSecondary)
            }
        }
    }
}

struct AnimatedStarsView: View {
    let count: Int
    @State private var visibleCount = 0

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(index < count ? .appAccent : .appTextSecondary.opacity(0.35))
                    .scaleEffect(index < visibleCount ? 1 : 0.3)
                    .opacity(index < visibleCount ? 1 : 0.2)
                    .shadow(color: index < visibleCount ? .appAccent.opacity(0.8) : .clear, radius: 12)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.15),
                        value: visibleCount
                    )
            }
        }
        .onAppear {
            visibleCount = count
            if count > 0 {
                HapticService.success()
            }
        }
    }
}

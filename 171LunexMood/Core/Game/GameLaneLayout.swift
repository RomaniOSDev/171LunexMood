import CoreGraphics

/// Общая разметка поля: 3 полосы, игрок внизу, объекты падают сверху.
struct GameLaneLayout {
    let width: CGFloat
    let height: CGFloat
    let laneCount: Int = 3
    let laneSpacing: CGFloat = 72

    var playerY: CGFloat { max(height * 0.78, 120) }
    var playerSize: CGFloat { 34 }
    var spawnY: CGFloat { -40 }
    var despawnY: CGFloat { height + 60 }

    func laneX(_ lane: Int) -> CGFloat {
        let center = width / 2
        let offset = CGFloat(lane - 1) * laneSpacing
        return center + offset
    }

    func laneIndex(for x: CGFloat) -> Int {
        let center = width / 2
        let relative = x - center
        if relative < -laneSpacing * 0.45 { return 0 }
        if relative > laneSpacing * 0.45 { return 2 }
        return 1
    }
}

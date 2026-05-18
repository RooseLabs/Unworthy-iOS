import CoreGraphics

extension CGPoint {
    func lerp(to other: CGPoint, t: CGFloat) -> CGPoint {
        CGPoint(x: x + (other.x - x) * t, y: y + (other.y - y) * t)
    }

    func distance(to point: CGPoint) -> CGFloat {
        hypot(point.x - x, point.y - y)
    }

    func length() -> CGFloat {
        hypot(x, y) // equivalent to sqrt(x * x + y * y)
    }

    func normalized() -> CGPoint {
        let len = length()
        guard len > 0 else { return CGPoint.zero }
        return self / len
    }

    func moveTowards(_ target: CGPoint, maxDistance: CGFloat) -> CGPoint {
        let toX = target.x - x
        let toY = target.y - y
        let sqDist = toX * toX + toY * toY
        if sqDist == 0 || (maxDistance >= 0 && sqDist <= maxDistance * maxDistance) {
            return target
        }
        let dist = sqrt(sqDist)
        return CGPoint(x: x + toX / dist * maxDistance, y: y + toY / dist * maxDistance)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        guard rhs != 0 else { return CGPoint.zero }
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

extension CGFloat {
    func lerp(to: CGFloat, t: CGFloat) -> CGFloat { self + (to - self) * t }
}

extension CGVector {
    static var zero: CGVector { CGVector(dx: 0, dy: 0) }

    func lerp(to other: CGVector, t: CGFloat) -> CGVector {
        CGVector(dx: dx + (other.dx - dx) * t, dy: dy + (other.dy - dy) * t)
    }
}

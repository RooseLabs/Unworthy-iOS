import CoreGraphics

struct ViewportMetrics {
    let targetSize: CGSize
    let viewSize: CGSize

    init(targetSize: CGSize = CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight),
         viewSize: CGSize) {
        self.targetSize = targetSize
        self.viewSize = viewSize
    }

    var scale: CGFloat {
        guard targetSize.width > 0, targetSize.height > 0 else { return 1 }
        return min(viewSize.width / targetSize.width, viewSize.height / targetSize.height)
    }

    var visibleWorldSize: CGSize {
        guard scale > 0 else { return targetSize }
        return CGSize(width: viewSize.width / scale, height: viewSize.height / scale)
    }

    func scenePoint(fromWorldPoint point: CGPoint) -> CGPoint {
        CGPoint(x: point.x * scale, y: point.y * scale)
    }

    func worldPoint(fromScenePoint point: CGPoint) -> CGPoint {
        guard scale > 0 else { return point }
        return CGPoint(x: point.x / scale, y: point.y / scale)
    }

    func clampWorldPoint(_ point: CGPoint, within bounds: CGRect) -> CGPoint {
        let halfWidth = visibleWorldSize.width / 2
        let halfHeight = visibleWorldSize.height / 2

        let minX = bounds.minX + halfWidth
        let maxX = bounds.maxX - halfWidth
        let minY = bounds.minY + halfHeight
        let maxY = bounds.maxY - halfHeight

        guard minX <= maxX, minY <= maxY else {
            return CGPoint(x: bounds.midX, y: bounds.midY)
        }

        let clampedX = min(max(point.x, minX), maxX)
        let clampedY = min(max(point.y, minY), maxY)
        return CGPoint(x: clampedX, y: clampedY)
    }
}

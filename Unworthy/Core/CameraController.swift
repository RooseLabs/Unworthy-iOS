import CoreGraphics
import Foundation

final class CameraController {
    private var bounds: [CGRect] = []
    private var followTarget: (() -> CGPoint)?
    private(set) var position: CGPoint = .zero
    var offset: CGVector = .zero

    func resetBounds(_ bounds: [CGRect]) {
        self.bounds = bounds
    }

    func addBounds(_ bounds: CGRect) {
        self.bounds.append(bounds)
    }

    func setFollowTarget(_ provider: @escaping () -> CGPoint, viewportMetrics: ViewportMetrics) {
        followTarget = provider
        position = initialPosition(viewportMetrics: viewportMetrics)
    }

    func update(deltaTime: TimeInterval, viewportMetrics: ViewportMetrics) -> CGPoint? {
        guard let followTarget else { return nil }
        let target = followTarget()
        guard let bounds = boundsContaining(target) else { return nil }
        let targetPosition = clampCameraCenter(for: target, bounds: bounds, viewportMetrics: viewportMetrics)
        let t = min(1, CGFloat(6.0 * deltaTime))
        position = position.lerp(to: targetPosition, t: t)
        return position
    }

    private func initialPosition(viewportMetrics: ViewportMetrics) -> CGPoint {
        guard let followTarget else { return position }
        let target = followTarget()
        guard let bounds = boundsContaining(target) else {
            return applyOffset(to: target)
        }
        return clampCameraCenter(for: target, bounds: bounds, viewportMetrics: viewportMetrics)
    }

    private func boundsContaining(_ point: CGPoint) -> CGRect? {
        bounds.first { $0.contains(point) }
    }

    private func clampCameraCenter(for target: CGPoint, bounds: CGRect, viewportMetrics: ViewportMetrics) -> CGPoint {
        let targetPosition = applyOffset(to: target)
        let halfWidth = viewportMetrics.visibleWorldSize.width / 2
        let halfHeight = viewportMetrics.visibleWorldSize.height / 2
        if bounds.width < halfWidth * 2 || bounds.height < halfHeight * 2 {
            return targetPosition
        }
        let clampedX = min(max(targetPosition.x, bounds.minX + halfWidth), bounds.maxX - halfWidth)
        let clampedY = min(max(targetPosition.y, bounds.minY + halfHeight), bounds.maxY - halfHeight)
        return CGPoint(x: clampedX, y: clampedY)
    }

    private func applyOffset(to target: CGPoint) -> CGPoint {
        CGPoint(x: target.x + offset.dx * GameConstants.pixelsPerUnit,
                y: target.y + offset.dy * GameConstants.pixelsPerUnit)
    }
}

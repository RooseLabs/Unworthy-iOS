import SpriteKit

final class GroundNode: SKShapeNode {
    init(rect: CGRect, zPosition: CGFloat, fillColor: SKColor = .white) {
        super.init()
        self.path = CGPath(rect: CGRect(origin: CGPoint(x: -rect.size.width / 2, y: -rect.size.height / 2), size: rect.size), transform: nil)
        self.position = CGPoint(x: rect.midX, y: rect.midY)
        self.fillColor = fillColor
        self.strokeColor = .clear
        self.lineWidth = 0
        self.isAntialiased = false
        self.zPosition = zPosition
        self.name = "Ground"
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }
}

import SpriteKit

final class ControlAnalogNode: SKNode, TouchResponsive {
    private let baseNode: SKShapeNode
    private let knobNode: SKShapeNode
    private let radius: CGFloat
    private let touchRadius: CGFloat

    private weak var activeTouch: UITouch?
    private(set) var axis = CGVector.zero

    init(radius: CGFloat = 140, touchRadius: CGFloat = 240, color: SKColor = .white) {
        self.radius = radius
        self.touchRadius = touchRadius
        baseNode = SKShapeNode(circleOfRadius: radius)
        knobNode = SKShapeNode(circleOfRadius: radius * 0.35)
        super.init()
        baseNode.strokeColor = color.withAlphaComponent(0.25)
        baseNode.lineWidth = 4
        baseNode.fillColor = color.withAlphaComponent(0.05)
        knobNode.fillColor = color.withAlphaComponent(0.35)
        knobNode.strokeColor = color.withAlphaComponent(0.45)
        knobNode.lineWidth = 3
        addChild(baseNode)
        knobNode.position = .zero
        addChild(knobNode)
        zPosition = GameConstants.layerUI
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginTouch(_ touch: UITouch, location: CGPoint) {
        guard activeTouch == nil, location.distance(to: position) <= touchRadius else { return }
        activeTouch = touch
        updateKnob(with: location)
    }

    func moveTouch(_ touch: UITouch, location: CGPoint) {
        guard activeTouch === touch else { return }
        updateKnob(with: location)
    }

    func endTouch(_ touch: UITouch) {
        guard activeTouch === touch else { return }
        activeTouch = nil
        axis = .zero
        knobNode.run(SKAction.move(to: .zero, duration: 0.08))
    }

    private func updateKnob(with location: CGPoint) {
        let offset = location - position
        let length = offset.length()
        if length <= radius {
            knobNode.position = offset
        } else {
            let clamped = offset * (radius / max(length, 0.001))
            knobNode.position = clamped
        }
        axis = CGVector(dx: knobNode.position.x / radius, dy: knobNode.position.y / radius)
    }
}

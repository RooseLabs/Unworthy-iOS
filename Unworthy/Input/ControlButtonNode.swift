import SpriteKit

final class ControlButtonNode: SKSpriteNode, TouchResponsive {
    private var activeTouches = Set<UITouch>()
    private let normalColor: SKColor
    private let pressedColor: SKColor
    private let hitRadius: CGFloat
    private let padding: CGFloat

    private var previousState = false
    private var currentState = false

    var isPressed: Bool { currentState }
    var wasTouched: Bool { currentState && !previousState }
    var isTouched: Bool { currentState && previousState }

    init(textureNamed name: String,
         radius: CGFloat,
         padding: CGFloat = 0,
         normalColor: SKColor = .white,
         pressedColor: SKColor = .white) {
        let texture = SKTexture(imageNamed: name)
        self.normalColor = normalColor.withAlphaComponent(0.5)
        self.pressedColor = pressedColor.withAlphaComponent(0.75)
        self.hitRadius = radius
        self.padding = padding
        let visualRadius = max(0, radius - padding)
        super.init(texture: texture,
                   color: self.normalColor,
                   size: CGSize(width: visualRadius * 2, height: visualRadius * 2))
        colorBlendFactor = 1
        isUserInteractionEnabled = false
        zPosition = GameConstants.layerUI
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginTouch(_ touch: UITouch, location: CGPoint) {
        guard contains(location: location) else { return }
        activeTouches.insert(touch)
        updateVisualState(isPressed: true)
    }

    func moveTouch(_ touch: UITouch, location: CGPoint) {
        guard activeTouches.contains(touch) || contains(location: location) else { return }
        if contains(location: location) {
            activeTouches.insert(touch)
            updateVisualState(isPressed: true)
        } else {
            activeTouches.remove(touch)
            updateVisualState(isPressed: !activeTouches.isEmpty)
        }
    }

    func endTouch(_ touch: UITouch) {
        guard activeTouches.contains(touch) else { return }
        activeTouches.remove(touch)
        updateVisualState(isPressed: !activeTouches.isEmpty)
    }

    func update() {
        let nextState = !activeTouches.isEmpty
        previousState = currentState
        currentState = nextState
        updateVisualState(isPressed: nextState)
    }

    private func contains(location: CGPoint) -> Bool {
        let dx = location.x - position.x
        let dy = location.y - position.y
        return dx * dx + dy * dy <= hitRadius * hitRadius
    }

    private func updateVisualState(isPressed: Bool) {
        let targetColor = isPressed ? pressedColor : normalColor
        if color != targetColor {
            color = targetColor
        }
    }
}

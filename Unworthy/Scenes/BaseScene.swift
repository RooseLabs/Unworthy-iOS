import SpriteKit

class BaseScene: SKScene, SKPhysicsContactDelegate {
    weak var coordinator: SceneCoordinator?
    let worldNode = SKNode()
    let uiNode = SKNode()
    let cameraNode = SKCameraNode()

    private var lastUpdateTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        if camera == nil {
            addChild(worldNode)
            camera = cameraNode
            addChild(cameraNode)
            cameraNode.addChild(uiNode)
        }
    }

    func normalizedPosition(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: (x - 0.5) * size.width, y: (y - 0.5) * size.height)
    }

    override func update(_ currentTime: TimeInterval) {
        let rawDelta = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        let delta = min(rawDelta, 1.0 / 30.0)
        update(deltaTime: delta)
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        lastUpdateTime = 0
        isPaused = false
    }

    var canPause: Bool {
        true
    }

    func update(deltaTime: TimeInterval) {
        // To be overridden by subclasses
    }
}

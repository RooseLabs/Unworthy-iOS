import SpriteKit
import CoreMotion

final class LevelScene: BaseScene {
    var inputState: LevelInputState?

    private let motionManager = CMMotionManager()
    private let mapLoader: TiledMapLoader
    private var collisions: [CGRect] = []
    private var killTriggers: [CGRect] = []
    private var cameraBounds: [CGRect] = []
    private var levelBounds: [CGRect] = []
    private var hazardNodes: [SKNode] = []
    private let cameraController = CameraController()

    private let debugNode = SKNode()

    private let solidRectangleTypes: Set<String> = ["Ground", "Platform"]

    private let player = PlayerNode()
    private let vignette = VignetteNode()
    private let fadeNode = FadeNode(size: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight))
    private var starsNodes: [StarsNode] = []

    private var viewportMetrics = ViewportMetrics(viewSize: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight))
    private var isRestarting = false

    override init(size: CGSize) {
        mapLoader = try! TiledMapLoader(mapName: "level")
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        buildScene()
        applyViewportLayout()
        setupFadeOverlay()
        fadeNode.fadeIn(duration: 1.5)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        applyViewportLayout()
        setupFadeOverlay()
    }

    private func buildScene() {
        backgroundColor = .black
        addMapLayers()
        addPlayer()
        setupCamera()

        if GameConstants.debug {
            debugNode.zPosition = GameConstants.layerForeground + 0.5
            worldNode.addChild(debugNode)
        }

        uiNode.addChild(vignette)
        vignette.position = .zero
    }

    private func setupFadeOverlay() {
        fadeNode.removeFromParent()
        fadeNode.size = CGSize(width: size.width, height: size.height)
        fadeNode.position = .zero
        uiNode.addChild(fadeNode)
    }

    private func applyViewportLayout() {
        guard size.width > 0, size.height > 0 else { return }
        viewportMetrics = ViewportMetrics(viewSize: size)
        worldNode.setScale(viewportMetrics.scale)
        vignette.resize(to: size)
        updateCamera(deltaTime: 0)
    }

    private func addMapLayers() {
        starsNodes.removeAll()
        collisions = solidRectangleObjects(in: "Ground") + solidRectangleObjects(in: "Platforms")
        killTriggers = mapLoader.rectangles(ofType: "KillTrigger", in: "KillTriggers")
        cameraBounds = mapLoader.rectangles(ofType: "CameraBounds", in: "Bounds")
        levelBounds = mapLoader.rectangles(ofType: "Boundary", in: "Bounds")

        hazardNodes.forEach { $0.removeFromParent() }
        hazardNodes.removeAll()
        addHazardNodes()

        cameraController.resetBounds(cameraBounds)

        let order = [
            "Background0": GameConstants.layerBackground0,
            "Background1": GameConstants.layerBackground1,
            "Background2": GameConstants.layerBackground2,
            "Ground": GameConstants.layerGround,
            "Platforms": GameConstants.layerPlatforms,
            "Objects": GameConstants.layerObjects,
            "Foreground": GameConstants.layerForeground
        ]

        for (name, z) in order {
            for object in mapLoader.objects(in: name) {
                guard object.visible ?? true else { continue }

                if solidRectangleTypes.contains(object.type) {
                    let node = GroundNode(rect: mapLoader.rect(for: object), zPosition: z)
                    worldNode.addChild(node)
                } else if object.type == "Stars" {
                    let starsRect = mapLoader.rect(for: object)
                    let starsNode = StarsNode(size: starsRect.size)
                    starsNode.position = starsRect.origin
                    starsNode.zPosition = z
                    worldNode.addChild(starsNode)
                    starsNodes.append(starsNode)
                } else {
                    guard let path = mapLoader.assetPath(for: object) else { continue }
                    let node = SKSpriteNode(imageNamed: path)
                    node.position = mapLoader.position(for: object)
                    node.zPosition = z
                    if mapLoader.isFlippedHorizontally(object) {
                        node.xScale = -1
                    }
                    worldNode.addChild(node)
                }
            }
        }
    }

    private func solidRectangleObjects(in layerName: String) -> [CGRect] {
        mapLoader.objects(in: layerName)
            .filter { ($0.visible ?? true) && solidRectangleTypes.contains($0.type) }
            .map { mapLoader.rect(for: $0) }
    }

    private func addPlayer() {
        if let spawn = mapLoader.objects(in: "Entities").first(where: { $0.type == "Player" }) {
            player.position = mapLoader.position(for: spawn)
        }
        player.levelScene = self
        worldNode.addChild(player)
    }

    private func setupCamera() {
        cameraController.setFollowTarget({ [weak player] in
            player?.position ?? .zero
        }, viewportMetrics: viewportMetrics)
    }

    override func update(deltaTime: TimeInterval) {
        for stars in starsNodes {
            stars.update(deltaTime: deltaTime)
        }
        player.update(deltaTime: deltaTime)
        updateCamera(deltaTime: deltaTime)
        updateDebugOverlays()
    }

    private func updateDebugOverlays() {
        guard GameConstants.debug else { return }
        debugNode.removeAllChildren()

        drawDebug(rect: player.hitbox, stroke: .cyan, fill: SKColor.clear)
        collisions.forEach { drawDebug(rect: $0, stroke: .yellow, fill: SKColor.clear) }
        killTriggers.forEach { drawDebug(rect: $0, stroke: .red, fill: SKColor.red.withAlphaComponent(0.2)) }
        cameraBounds.forEach { drawDebug(rect: $0, stroke: .green, fill: SKColor.clear) }
        levelBounds.forEach { drawDebug(rect: $0, stroke: .purple, fill: SKColor.clear) }
    }

    private func drawDebug(rect: CGRect, stroke: SKColor, fill: SKColor) {
        let shape = SKShapeNode(rect: rect)
        shape.strokeColor = stroke
        shape.fillColor = fill
        shape.lineWidth = 2
        shape.isAntialiased = false
        debugNode.addChild(shape)
    }

    private func updateCamera(deltaTime: TimeInterval) {
        let desiredOffset = CGVector(dx: player.isFacingRight ? 1 : -1, dy: 0)
        let lerpSpeed: CGFloat = player.isAttacking ? 1.5 : 3.0
        let t = min(1, lerpSpeed * CGFloat(deltaTime))
        cameraController.offset = cameraController.offset.lerp(to: desiredOffset, t: t)

        if let cameraWorldPosition = cameraController.update(deltaTime: deltaTime, viewportMetrics: viewportMetrics) {
            cameraNode.position = viewportMetrics.scenePoint(fromWorldPoint: cameraWorldPosition)
        }
    }

    private func addHazardNodes() {
        for rect in killTriggers {
            let node = SKNode()
            node.position = CGPoint(x: rect.midX, y: rect.midY)
            let body = SKPhysicsBody(rectangleOf: rect.size)
            body.isDynamic = false
            body.affectedByGravity = false
            body.categoryBitMask = PhysicsCategory.hazard
            body.collisionBitMask = PhysicsCategory.none
            body.contactTestBitMask = PhysicsCategory.player
            node.physicsBody = body
            hazardNodes.append(node)
            worldNode.addChild(node)
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask & PhysicsCategory.player != 0 {
            player.handleContactBegan(with: contact.bodyB)
        } else if contact.bodyB.categoryBitMask & PhysicsCategory.player != 0 {
            player.handleContactBegan(with: contact.bodyA)
        }
    }

    private func respawn() {
        if let spawn = mapLoader.objects(in: "Entities").first(where: { $0.type == "Player" }) {
            player.position = mapLoader.position(for: spawn)
            player.resetPhysicsState()
            setupCamera()
            updateCamera(deltaTime: 0)
        }
    }

    private func restartWithFade() {
        guard !isRestarting else { return }
        isRestarting = true

        vignette.flash(to: .red, duration: 0.25)
        fadeNode.fadeOut(duration: 1.5) { [weak self] in
            guard let self else { return }
            self.respawn()
            self.fadeNode.fadeIn(duration: 1.5) { [weak self] in
                self?.isRestarting = false
            }
        }
    }

    func handlePlayerHazardContact() {
        restartWithFade()
    }

    var playerCollisions: [CGRect] {
        collisions
    }
}

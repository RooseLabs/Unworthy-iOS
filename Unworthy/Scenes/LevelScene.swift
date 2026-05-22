import SpriteKit
import CoreMotion

final class LevelScene: BaseScene {
    var inputState: LevelInputState?
    var onTouchControlsAlphaChanged: ((CGFloat) -> Void)?

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
    private(set) var enemies: [FlyeNode] = []
    private let hudNode = HUDNode()
    private let pauseMenu = PauseMenuNode()
    private var playerSpawnPosition: CGPoint = .zero

    private var viewportMetrics = ViewportMetrics(viewSize: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight))
    private var isRestarting = false
    private var isFadeTransitionActive = false

    private let idleFadeDelay: TimeInterval = 10
    private let idleFadeSpeed: CGFloat = 1.5
    private var timeSinceLastInputAny: TimeInterval = 0
    private var timeSinceLastTouch: TimeInterval = 0
    private var hudAlpha: CGFloat = 1
    private var touchControlsAlpha: CGFloat = 1
    private var inputMode: InputMode = .touch

    override var canPause: Bool {
        !isFadeTransitionActive
    }

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
        GameSession.shared.activeLevel = self
        buildScene()
        applyViewportLayout()
        setupFadeOverlay()
        isFadeTransitionActive = true
        fadeNode.fadeIn(duration: 1.5) { [weak self] in
            self?.isFadeTransitionActive = false
        }
    }

    override func willMove(from view: SKView) {
        flushSessionStats()
        if GameSession.shared.activeLevel === self {
            GameSession.shared.activeLevel = nil
        }
        super.willMove(from: view)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        applyViewportLayout()
        setupFadeOverlay()
    }

    override func pause() {
        flushSessionStats()
        pauseMenu.isHidden = false
        super.pause()
    }

    override func resume() {
        pauseMenu.isHidden = true
        super.resume()
        markTouchInteraction()
    }

    private func buildScene() {
        backgroundColor = .black
        addMapLayers()
        addEntities()
        setupCamera()

        if GameConstants.debug {
            debugNode.zPosition = GameConstants.layerForeground + 0.5
            worldNode.addChild(debugNode)
        }

        uiNode.addChild(vignette)
        vignette.position = .zero

        hudNode.zPosition = GameConstants.layerUI
        uiNode.addChild(hudNode)
        hudNode.hpIndicator.update(health: player.health)
        hudNode.statsCounter.update(
            kills: GameSession.shared.data.enemiesDefeated,
            deaths: GameSession.shared.data.deaths
        )
        layoutHUD()

        pauseMenu.onResume = { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(name: .levelDidRequestResume, object: self)
        }
        pauseMenu.onRestart = { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(name: .levelDidRequestResume, object: self)
            self.restartWithFade()
        }
        pauseMenu.onReturnToMenu = { [weak self] in
            self?.flushSessionStats()
            self?.coordinator?.presentMainMenu()
        }
        uiNode.addChild(pauseMenu)
        pauseMenu.resize(to: size)
    }

    private func layoutHUD() {
        hudNode.layout(sceneSize: size, safeInsets: safeAreaInsets, scale: viewportMetrics.scale)
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
        layoutHUD()
        pauseMenu.resize(to: size)
        updateCamera(deltaTime: 0)
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        layoutHUD()
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

    private func addEntities() {
        let entityObjects = mapLoader.objects(in: "Entities")
        guard let spawn = entityObjects.first(where: { $0.type == "Player" }) else {
            assertionFailure("LevelScene: no \"Player\" spawn found in Entities layer; objects=\(entityObjects.map(\.type))")
            return
        }
        playerSpawnPosition = mapLoader.position(for: spawn)
        player.setSpawnPosition(playerSpawnPosition)
        player.levelScene = self
        worldNode.addChild(player)

        for entity in entityObjects where entity.type == "Flye" {
            let flye = FlyeNode(spawnPosition: mapLoader.position(for: entity), level: self)
            worldNode.addChild(flye)
            enemies.append(flye)
        }
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
        for enemy in enemies {
            enemy.update(deltaTime: deltaTime, player: player)
        }
        updateCamera(deltaTime: deltaTime)
        hudNode.hpIndicator.update(health: max(player.health, 0))
        hudNode.statsCounter.update(
            kills: GameSession.shared.data.enemiesDefeated + player.killCount,
            deaths: GameSession.shared.data.deaths + player.deathCount
        )
        updateDebugOverlays()
        updateHUDFade(deltaTime: deltaTime)
    }

    private func updateHUDFade(deltaTime: TimeInterval) {
        guard !isFadeTransitionActive else { return }

        if timeSinceLastInputAny >= idleFadeDelay {
            let next = hudAlpha - idleFadeSpeed * CGFloat(deltaTime)
            hudAlpha = max(0, next)
            hudNode.alpha = hudAlpha
        } else {
            timeSinceLastInputAny += deltaTime
        }

        if timeSinceLastTouch >= idleFadeDelay {
            let next = touchControlsAlpha - idleFadeSpeed * CGFloat(deltaTime)
            touchControlsAlpha = max(0, next)
            onTouchControlsAlphaChanged?(touchControlsAlpha)
        } else {
            timeSinceLastTouch += deltaTime
        }
    }

    func markTouchInteraction() {
        inputMode = .touch
        timeSinceLastInputAny = 0
        timeSinceLastTouch = 0
        wakeHUD()
        wakeTouchControls()
    }

    func markKeyboardInteraction() {
        inputMode = .keyboard
        timeSinceLastInputAny = 0
        wakeHUD()
    }

    func markHUDActivity() {
        timeSinceLastInputAny = 0
        wakeHUD()
        if inputMode == .touch {
            timeSinceLastTouch = 0
            wakeTouchControls()
        }
    }

    private func wakeHUD() {
        guard hudAlpha != 1 else { return }
        hudAlpha = 1
        hudNode.alpha = 1
    }

    private func wakeTouchControls() {
        guard touchControlsAlpha != 1 else { return }
        touchControlsAlpha = 1
        onTouchControlsAlphaChanged?(1)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        markTouchInteraction()
        if !pauseMenu.isHidden, let touch = touches.first {
            _ = pauseMenu.handleTouchBegan(scenePoint: touch.location(in: self))
            return
        }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !pauseMenu.isHidden, let touch = touches.first {
            pauseMenu.handleTouchMoved(scenePoint: touch.location(in: self))
            return
        }
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !pauseMenu.isHidden, let touch = touches.first {
            pauseMenu.handleTouchEnded(scenePoint: touch.location(in: self))
            return
        }
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !pauseMenu.isHidden {
            pauseMenu.handleTouchCancelled()
            return
        }
        super.touchesCancelled(touches, with: event)
    }

    func flushSessionStats() {
        let kills = player.killCount
        let deaths = player.deathCount
        GameSession.shared.recordSession(kills: kills, deaths: deaths)
        player.killCount = 0
        player.deathCount = 0
        hudNode.statsCounter.update(
            kills: GameSession.shared.data.enemiesDefeated,
            deaths: GameSession.shared.data.deaths
        )
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
        player.reset()
        player.setSpawnPosition(playerSpawnPosition, resetPhysics: false)
        for enemy in enemies {
            enemy.reset()
        }
        hudNode.hpIndicator.update(health: player.health)
        setupCamera()
        updateCamera(deltaTime: 0)
    }

    func restartWithFade() {
        guard !isRestarting else { return }
        isRestarting = true
        isFadeTransitionActive = true
        flushSessionStats()

        vignette.flash(to: .red, duration: 0.25)
        fadeNode.fadeOut(duration: 1.5) { [weak self] in
            guard let self else { return }
            self.respawn()
            self.fadeNode.fadeIn(duration: 1.5) { [weak self] in
                self?.isRestarting = false
                self?.isFadeTransitionActive = false
            }
        }
    }

    func flashVignetteRed() {
        vignette.flash(to: .red, duration: 0.25)
    }

    func handlePlayerHazardContact() {
        restartWithFade()
    }

    var playerCollisions: [CGRect] {
        collisions
    }
}

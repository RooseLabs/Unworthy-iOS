import SpriteKit
import CoreMotion

final class MainMenuScene: BaseScene {
    private let motionManager = CMMotionManager()

    private let title = SKSpriteNode(texture: SKTexture(imageNamed: "title"))
    private let character = SKSpriteNode(texture: SKTexture(imageNamed: "character_fall"))
    private let tapToBegin = SKSpriteNode(texture: SKTexture(imageNamed: "taptobegin"))
    private let starsNode = StarsNode(size: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight))

    private var characterStart: CGPoint = .zero
    private var characterEnd: CGPoint = .zero
    private var startFalling = false
    private var animationStart: TimeInterval = 0
    private let animationDuration: TimeInterval = 1.8
    private var tapBlinkTime: TimeInterval = 0

    private let fadeNode = FadeNode(size: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight))
    private var hasTriggeredLevelTransition = false
    private var hasStartedFadeOut = false

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .black
        buildLayout()
        motionManager.startGyroUpdates()
        AssetProvider.Instance.playBackgroundMusic(named: "Midnight_Dreams")
        setupFadeOverlay()
        fadeNode.fadeIn(duration: 1.5)
    }

    private func setupFadeOverlay() {
        fadeNode.removeFromParent()
        fadeNode.size = CGSize(width: size.width, height: size.height)
        fadeNode.position = .zero
        uiNode.addChild(fadeNode)
    }

    private func buildLayout() {
        starsNode.position = .zero
        starsNode.zPosition = GameConstants.layerBackground0
        worldNode.addChild(starsNode)

        title.position = normalizedPosition(x: 0.1, y: 0.8)
        title.anchorPoint = CGPoint(x: 0, y: 1)
        title.zPosition = GameConstants.layerObjects
        worldNode.addChild(title)

        character.position = normalizedPosition(x: 0.75, y: 0.5)
        characterStart = character.position
        characterEnd = CGPoint(x: character.position.x, y: -size.height / 2 - character.size.height)
        character.zPosition = GameConstants.layerEntities
        worldNode.addChild(character)

        tapToBegin.position = normalizedPosition(x: 0.12, y: 0.3)
        tapToBegin.anchorPoint = CGPoint(x: 0, y: 1)
        tapToBegin.zPosition = GameConstants.layerForeground
        worldNode.addChild(tapToBegin)
    }

    override func update(deltaTime: TimeInterval) {
        starsNode.update(deltaTime: deltaTime)

        tapBlinkTime += deltaTime * 3
        tapToBegin.alpha = 0.5 + 0.5 * CGFloat(sin(tapBlinkTime))

        if let gyro = motionManager.gyroData {
            let offset = CGPoint(x: gyro.rotationRate.y * 60, y: gyro.rotationRate.x * 30)
            if !startFalling {
                let target = characterStart + offset
                character.position = character.position.lerp(to: target, t: 0.3)
            }
            let rotation = CGFloat(-gyro.rotationRate.z * 6)
            character.zRotation = character.zRotation.lerp(to: rotation, t: 0.1)
        }

        if startFalling {
            if animationStart == 0 {
                animationStart = CACurrentMediaTime()
                if !hasStartedFadeOut {
                    hasStartedFadeOut = true
                    fadeNode.fadeOut(duration: 1.5)
                }
            }
            let t = min(1.0, (CACurrentMediaTime() - animationStart) / animationDuration)
            let eased = 1 - cos(t * .pi / 2)
            character.position = characterStart.lerp(to: characterEnd, t: eased)
            if t >= 1.0 {
                startFalling = false
                guard !hasTriggeredLevelTransition else { return }
                hasTriggeredLevelTransition = true
                if fadeNode.hasActions() {
                    fadeNode.run(.sequence([
                        .wait(forDuration: 0.01),
                        .run { [weak self] in
                            self?.waitForFadeCompletionThenPresentLevel()
                        }
                    ]))
                } else {
                    coordinator?.presentLevel()
                }
            }
        }
    }

    private func waitForFadeCompletionThenPresentLevel() {
        if fadeNode.hasActions() {
            fadeNode.run(.sequence([
                .wait(forDuration: 0.01),
                .run { [weak self] in
                    self?.waitForFadeCompletionThenPresentLevel()
                }
            ]))
            return
        }
        coordinator?.presentLevel()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !startFalling else { return }
        startFalling = true
    }
}

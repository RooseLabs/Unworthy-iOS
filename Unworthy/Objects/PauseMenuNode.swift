import SpriteKit

final class PauseMenuNode: SKNode {
    private let background = SKShapeNode()
    private let resumeLabel = SKLabelNode()
    private let restartLabel = SKLabelNode()
    private let returnLabel = SKLabelNode()
    private let normalColor = SKColor.white
    private let pressedColor = SKColor(red: 0.87, green: 0.06, blue: 0.05, alpha: 1.0)
    private weak var activeLabel: SKLabelNode?

    var onResume: (() -> Void)?
    var onRestart: (() -> Void)?
    var onReturnToMenu: (() -> Void)?

    override init() {
        super.init()
        let menuFontName = FontLoader.getFont(fileName: "chiller.ttf") ?? "Helvetica-Bold"
        resumeLabel.fontName = menuFontName
        restartLabel.fontName = menuFontName
        returnLabel.fontName = menuFontName
        isHidden = true
        zPosition = GameConstants.layerOverlay

        background.fillColor = SKColor.black.withAlphaComponent(0.75)
        background.strokeColor = .clear
        addChild(background)

        for label in [resumeLabel, restartLabel, returnLabel] {
            label.fontColor = normalColor
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            addChild(label)
        }
        resumeLabel.text = "Resume"
        restartLabel.text = "Restart"
        returnLabel.text = "Main Menu"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static let baseFontSize: CGFloat = 290

    func resize(to size: CGSize) {
        background.path = CGPath(
            rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height),
            transform: nil
        )

        let scale = GameConstants.targetHeight > 0 ? size.height / GameConstants.targetHeight : 1
        let fontSize = Self.baseFontSize * scale
        for label in [resumeLabel, restartLabel, returnLabel] {
            label.fontSize = fontSize
        }

        let spacing: CGFloat = resumeLabel.fontSize * 1.8
        resumeLabel.position  = CGPoint(x: 0, y:  spacing)
        restartLabel.position = CGPoint(x: 0, y:  0)
        returnLabel.position  = CGPoint(x: 0, y: -spacing)
    }

    func handleTap(scenePoint: CGPoint) -> Bool {
        guard !isHidden, let scene else { return false }
        let local = convert(scenePoint, from: scene)
        if resumeLabel.contains(local) {
            onResume?()
            return true
        }
        if restartLabel.contains(local) {
            onRestart?()
            return true
        }
        if returnLabel.contains(local) {
            onReturnToMenu?()
            return true
        }
        return false
    }

    func handleTouchBegan(scenePoint: CGPoint) -> Bool {
        guard !isHidden, let scene else { return false }
        let local = convert(scenePoint, from: scene)
        if resumeLabel.contains(local) {
            setActiveLabel(resumeLabel)
            return true
        }
        if restartLabel.contains(local) {
            setActiveLabel(restartLabel)
            return true
        }
        if returnLabel.contains(local) {
            setActiveLabel(returnLabel)
            return true
        }
        return false
    }

    func handleTouchMoved(scenePoint: CGPoint) {
        guard !isHidden, let scene, let activeLabel else { return }
        let local = convert(scenePoint, from: scene)
        let isInside = activeLabel.contains(local)
        activeLabel.fontColor = isInside ? pressedColor : normalColor
    }

    func handleTouchEnded(scenePoint: CGPoint) {
        guard !isHidden, let scene, let activeLabel else { return }
        let local = convert(scenePoint, from: scene)
        let shouldTrigger = activeLabel.contains(local)
        let triggeredLabel = activeLabel
        clearActiveLabel()
        if shouldTrigger {
            if triggeredLabel === resumeLabel { onResume?() }
            else if triggeredLabel === restartLabel { onRestart?() }
            else if triggeredLabel === returnLabel { onReturnToMenu?() }
        }
    }

    func handleTouchCancelled() {
        clearActiveLabel()
    }

    private func setActiveLabel(_ label: SKLabelNode) {
        clearActiveLabel()
        activeLabel = label
        label.fontColor = pressedColor
    }

    private func clearActiveLabel() {
        activeLabel?.fontColor = normalColor
        activeLabel = nil
    }
}

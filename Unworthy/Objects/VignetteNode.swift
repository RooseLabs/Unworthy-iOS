import SpriteKit

final class VignetteNode: SKSpriteNode {
    init(textureNamed name: String = "vignette") {
        let texture = SKTexture(imageNamed: name)
        super.init(texture: texture, color: .black, size: texture.size())
        colorBlendFactor = 1.0
        alpha = 0.8
        zPosition = GameConstants.layerVignette
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resize(to size: CGSize) {
        self.size = size
    }

    func flash(to color: SKColor, duration: TimeInterval) {
        removeAllActions()
        let originalColor = self.color
        let originalAlpha = self.alpha
        run(SKAction.sequence([
            SKAction.group([
                SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: duration),
                SKAction.fadeAlpha(to: 1.0, duration: duration)
            ]),
            SKAction.group([
                SKAction.colorize(with: originalColor, colorBlendFactor: 1.0, duration: duration),
                SKAction.fadeAlpha(to: originalAlpha, duration: duration)
            ])
        ]))
    }
}

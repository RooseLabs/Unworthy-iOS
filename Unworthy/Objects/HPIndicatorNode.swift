import SpriteKit

final class HPIndicatorNode: SKNode {
    private let texture = SKTexture(imageNamed: "life_clock")
    private let spacing: CGFloat = 100
    private var icons: [SKSpriteNode] = []
    private var lastHealth: Int = -1

    func update(health: Int) {
        guard health != lastHealth else { return }
        lastHealth = health
        let iconSize = texture.size()
        while icons.count < max(health, 0) {
            let icon = SKSpriteNode(texture: texture)
            icon.anchorPoint = CGPoint(x: 0, y: 1)
            icon.position = CGPoint(
                x: CGFloat(icons.count) * (iconSize.width + spacing),
                y: 0
            )
            addChild(icon)
            icons.append(icon)
        }
        for (i, icon) in icons.enumerated() {
            icon.isHidden = i >= health
        }
    }
}

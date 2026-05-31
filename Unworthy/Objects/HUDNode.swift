import SpriteKit
import UIKit

final class HUDNode: SKNode {
    let hpIndicator = HPIndicatorNode()
    let statsCounter = StatsCounterNode()

    override init() {
        super.init()
        addChild(hpIndicator)
        addChild(statsCounter)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(sceneSize: CGSize, safeInsets: UIEdgeInsets, scale: CGFloat) {
        hpIndicator.setScale(scale)
        statsCounter.setScale(scale)

        let safeWidth = max(sceneSize.width - safeInsets.left - safeInsets.right, 0)
        let safeHeight = max(sceneSize.height - safeInsets.top - safeInsets.bottom, 0)
        let safeMinX = -sceneSize.width / 2 + safeInsets.left
        let safeMaxY = sceneSize.height / 2 - safeInsets.top

        hpIndicator.position = CGPoint(
            x: safeMinX + safeWidth * 0.025,
            y: safeMaxY - safeHeight * 0.05
        )

        let pauseAnchorX: CGFloat = 0.895
        let pauseAnchorY: CGFloat = 0.945
        statsCounter.position = CGPoint(
            x: safeMinX + safeWidth * pauseAnchorX,
            y: safeMaxY - safeHeight * (1 - pauseAnchorY)
        )
    }
}

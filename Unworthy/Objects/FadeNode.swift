import SpriteKit

final class FadeNode: SKSpriteNode {
    private var completion: (() -> Void)?

    init(size: CGSize) {
        super.init(texture: nil, color: .black, size: size)
        zPosition = 10_000
        alpha = 0
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fadeIn(duration: TimeInterval, completion: (() -> Void)? = nil) {
        runFade(to: 0, from: 1, duration: duration, completion: completion)
    }

    func fadeOut(duration: TimeInterval, completion: (() -> Void)? = nil) {
        runFade(to: 1, from: 0, duration: duration, completion: completion)
    }

    private func runFade(to targetAlpha: CGFloat, from startAlpha: CGFloat, duration: TimeInterval, completion: (() -> Void)?) {
        removeAction(forKey: "fade")
        isHidden = false
        alpha = startAlpha
        self.completion = completion

        let fade = SKAction.fadeAlpha(to: targetAlpha, duration: duration)
        let done = SKAction.run { [weak self] in
            guard let self else { return }
            if targetAlpha <= 0 {
                self.isHidden = true
            }
            let onCompleted = self.completion
            self.completion = nil
            onCompleted?()
        }

        run(.sequence([fade, done]), withKey: "fade")
    }
}

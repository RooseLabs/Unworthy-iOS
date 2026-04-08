import SpriteKit

final class PlayerNode: SKSpriteNode {
    var velocity = CGVector(dx: 0, dy: 0)
    var isGrounded = false
    var maxFallSpeed: CGFloat = 1200
    var moveSpeed: CGFloat = 900
    var jumpForce: CGFloat = 1800

    private let animationLibrary = try? AnimationLibrary.load(name: "player")
    private lazy var animator: SpriteAnimator? = {
        guard let library = animationLibrary else { return nil }
        return SpriteAnimator(node: self, library: library)
    }()
    private var lastPosition: CGPoint = .zero

    init() {
        let size = CGSize(width: 200, height: 320)
        super.init(texture: SKTexture(imageNamed: "Player1"), color: .white, size: size)
        name = "Player"
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        zPosition = GameConstants.layerEntities
        lastPosition = position
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(deltaTime: TimeInterval, inputAxis: CGFloat, wantsJump: Bool, collisions: [CGRect]) {
        let dt = CGFloat(deltaTime)
        let wasGrounded = isGrounded
        velocity.dy -= GameConstants.gravity * GameConstants.pixelsPerUnit * dt
        velocity.dy = max(velocity.dy, -maxFallSpeed)
        velocity.dx = inputAxis * moveSpeed

        var newPosition = position
        newPosition.x += velocity.dx * dt
        newPosition.y += velocity.dy * dt

        // Simple AABB collision resolve
        let playerRect = CGRect(x: newPosition.x - size.width / 2,
                                y: newPosition.y - size.height / 2,
                                width: size.width,
                                height: size.height)
        isGrounded = false
        for rect in collisions {
            if playerRect.intersects(rect) {
                // Resolve only vertical first
                if position.y >= rect.maxY {
                    newPosition.y = rect.maxY + size.height / 2
                    velocity.dy = 0
                    isGrounded = true
                } else if position.y <= rect.minY {
                    newPosition.y = rect.minY - size.height / 2
                    velocity.dy = 0
                }
            }
        }

        if wantsJump && isGrounded {
            velocity.dy = jumpForce
            isGrounded = false
        }

        position = newPosition
        let delta = CGVector(dx: position.x - lastPosition.x, dy: position.y - lastPosition.y)
        updateAnimationState(wasGrounded: wasGrounded, deltaPosition: delta)
        lastPosition = position
    }

    private func updateAnimationState(wasGrounded: Bool, deltaPosition: CGVector) {
        guard let animator else { return }
        if !isGrounded {
            let isRising = deltaPosition.dy > 1
            animator.play(isRising ? "jump" : "fall", force: true)
            return
        }
        if !wasGrounded {
            animator.play("land") { [weak self] in
                self?.animator?.play("idle")
            }
            return
        }
        let movingHorizontally = abs(deltaPosition.dx) > 1
        if movingHorizontally {
            if animator.currentAnimation == "walkLoop" || animator.currentAnimation == "walkStart" { return }
            animator.play("walkStart") { [weak self] in
                self?.animator?.play("walkLoop")
            }
            return
        }
        if animator.currentAnimation == "walkLoop" || animator.currentAnimation == "walkStart" {
            animator.play("walkEnd") { [weak self] in
                self?.animator?.play("idle")
            }
        } else if animator.currentAnimation != "idle" {
            animator.play("idle")
        }
    }
}

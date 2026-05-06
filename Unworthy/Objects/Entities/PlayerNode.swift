import SpriteKit

final class PlayerNode: SKSpriteNode {
    var velocity = CGVector(dx: 0, dy: 0)
    var isGrounded = false
    var maxFallSpeed: CGFloat = 1200
    var moveSpeed: CGFloat = 900
    var moveSpeedWhileAttacking: CGFloat = 180
    var jumpForce: CGFloat = 1800

    private var isFacingRight = true
    private var pressedAttack = false
    private var isAttacking = false
    private var lastAttackAnimation = ""
    private var attackComboTimeframe: TimeInterval = 1.0
    private var attackComboTimer: TimeInterval = 0
    private var attackCooldown: TimeInterval = 0.2
    private var attackCooldownTimer: TimeInterval = 0
    private var pendingAttackEnd = false
    private var attackEffectOffset = CGVector(dx: 130, dy: 105)

    private let animationLibrary = try? AnimationLibrary.load(name: "player")
    private lazy var animator: SpriteAnimator? = {
        guard let library = animationLibrary else { return nil }
        return SpriteAnimator(node: self, library: library)
    }()
    private var lastPosition: CGPoint = .zero

    private let attackEffectLibrary = try? AnimationLibrary.load(name: "attack_effects")
    private let attackEffectNode = SKSpriteNode()
    private lazy var attackEffectAnimator: SpriteAnimator? = {
        guard let library = attackEffectLibrary else { return nil }
        return SpriteAnimator(node: attackEffectNode, library: library)
    }()

    init() {
        let size = CGSize(width: 200, height: 320)
        super.init(texture: SKTexture(imageNamed: "Player1"), color: .white, size: size)
        name = "Player"
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        zPosition = GameConstants.layerEntities
        lastPosition = position

        if let texture = attackEffectLibrary?.firstTexture() {
            attackEffectNode.texture = texture
            attackEffectNode.size = texture.size()
        }
        attackEffectNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        attackEffectNode.position = CGPoint(x: attackEffectOffset.dx, y: attackEffectOffset.dy)
        attackEffectNode.zPosition = GameConstants.layerEntities + 0.01
        attackEffectNode.isHidden = true
        addChild(attackEffectNode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(deltaTime: TimeInterval, inputAxis: CGFloat, wantsJump: Bool, wantsAttack: Bool, collisions: [CGRect]) {
        let dt = CGFloat(deltaTime)
        if attackCooldownTimer > 0 {
            attackCooldownTimer = max(0, attackCooldownTimer - deltaTime)
        }
        if attackComboTimer > 0 {
            attackComboTimer = max(0, attackComboTimer - deltaTime)
        } else {
            lastAttackAnimation = ""
        }

        pressedAttack = wantsAttack
        if pressedAttack {
            performAttack()
        }

        updateFacingDirection(inputAxis: inputAxis)

        let wasGrounded = isGrounded
        velocity.dy -= GameConstants.gravity * GameConstants.pixelsPerUnit * dt
        velocity.dy = max(velocity.dy, -maxFallSpeed)
        let currentMoveSpeed = (pressedAttack || isAttacking) ? moveSpeedWhileAttacking : moveSpeed
        velocity.dx = inputAxis * currentMoveSpeed

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

    private func performAttack() {
        guard attackCooldownTimer <= 0 else {
            pressedAttack = false
            return
        }
        attackComboTimer = attackComboTimeframe
        attackCooldownTimer = attackCooldown
        isAttacking = true
        attackEffectNode.isHidden = false
        attackEffectNode.position = CGPoint(x: attackEffectOffset.dx, y: attackEffectOffset.dy)
        attackEffectAnimator?.play("attack", force: true) { [weak self] in
            self?.attackEffectNode.isHidden = true
        }
    }

    private func updateFacingDirection(inputAxis: CGFloat) {
        if inputAxis < -0.05, isFacingRight {
            setFacingDirection(false)
        } else if inputAxis > 0.05, !isFacingRight {
            setFacingDirection(true)
        }
    }

    private func setFacingDirection(_ facingRight: Bool) {
        guard isFacingRight != facingRight else { return }
        isFacingRight = facingRight
        xScale = facingRight ? 1 : -1
    }

    private func updateAnimationState(wasGrounded: Bool, deltaPosition: CGVector) {
        guard let animator else { return }
        let isAnimationRunning = action(forKey: "animation") != nil
        if pendingAttackEnd {
            pendingAttackEnd = false
            animator.play("attackEnd", force: true)
            return
        }
        if pressedAttack {
            let nextAnimation = lastAttackAnimation == "attack1" ? "attack2" : "attack1"
            lastAttackAnimation = nextAnimation
            animator.play(nextAnimation, force: true) { [weak self] in
                self?.pendingAttackEnd = true
                self?.isAttacking = false
            }
            return
        }
        if isAttacking {
            return
        }

        let isMovingHorizontally = abs(deltaPosition.dx) > 1
        let isMovingVertically = abs(deltaPosition.dy) > 1

        if !isGrounded {
            if isMovingVertically {
                if deltaPosition.dy > 0 {
                    if animator.currentAnimation != "jump" {
                        animator.play("jump")
                    }
                } else if animator.currentAnimation != "fall" {
                    animator.play("fall")
                }
            }
            if animator.currentAnimation == "jump" || animator.currentAnimation == "fall" {
                return
            }
            if isMovingHorizontally {
                return
            }
        }

        if isGrounded, animator.currentAnimation == "fall" {
            animator.play("land", force: true)
            return
        }

        if animator.currentAnimation == "land", isAnimationRunning {
            return
        }

        if isMovingHorizontally {
            if !isGrounded {
                return
            }
            if animator.currentAnimation == "walkLoop" || animator.currentAnimation == "walkStart" {
                return
            }
            animator.play("walkStart") { [weak self] in
                self?.animator?.play("walkLoop")
            }
            return
        }

        if animator.currentAnimation == "walkLoop" || animator.currentAnimation == "walkStart" {
            animator.play("walkEnd") { [weak self] in
                self?.animator?.play("idle")
            }
            return
        }

        if animator.currentAnimation != "idle" {
            animator.play("idle")
        }
    }
}

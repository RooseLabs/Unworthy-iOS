import SpriteKit

final class PlayerNode: SKSpriteNode {
    var velocity = CGVector(dx: 0, dy: 0)
    var isGrounded = false
    var maxFallSpeed: CGFloat = 6 * GameConstants.pixelsPerUnit
    var moveSpeed: CGFloat = 2.5 * GameConstants.pixelsPerUnit
    var moveSpeedWhileAttacking: CGFloat = 0.5 * GameConstants.pixelsPerUnit
    var jumpForce: CGFloat = 6.2 * GameConstants.pixelsPerUnit
    var gravityScale: CGFloat = 1.5

    private var facingRight = true
    private var pressedAttack = false
    private var attacking = false
    private var lastAttackAnimation = ""
    private var attackComboTimeframe: TimeInterval = 1.0
    private var attackComboTimer: TimeInterval = 0
    private var attackCooldown: TimeInterval = 0.2
    private var attackCooldownTimer: TimeInterval = 0
    private var pendingAttackEnd = false
    private var attackEffectOffset = CGVector(dx: 130, dy: 105)
    private var idleAnimationTimer: TimeInterval = 0

    private let hitboxWidth: CGFloat = 77.55
    private let hitboxHeight: CGFloat = 305
    private let hitboxOffsetRight: CGFloat = 93.09

    private let animationLibrary = try? AnimationLibrary.load(name: "player")
    private lazy var animator: SpriteAnimator? = {
        guard let library = animationLibrary else { return nil }
        return SpriteAnimator(node: self, library: library)
    }()
    private var lastPosition: CGPoint = .zero

    weak var levelScene: LevelScene?

    private let attackEffectLibrary = try? AnimationLibrary.load(name: "attack_effects")
    private let attackEffectNode = SKSpriteNode()
    private lazy var attackEffectAnimator: SpriteAnimator? = {
        guard let library = attackEffectLibrary else { return nil }
        return SpriteAnimator(node: attackEffectNode, library: library)
    }()

    init() {
        let texture = SKTexture(imageNamed: "Player1")
        super.init(texture: texture, color: .white, size: texture.size())
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

    func update(deltaTime: TimeInterval) {
        let inputState = levelScene?.inputState
        let inputAxis = CGFloat(inputState?.movementAxis.dx ?? 0)
        let wantsJump = inputState?.consumeJumpRequest() ?? false
        let wantsAttack = inputState?.consumeAttackRequest() ?? false
        let collisions = levelScene?.playerCollisions ?? []
        let dt = CGFloat(deltaTime)
        if attackCooldownTimer > 0 {
            attackCooldownTimer = max(0, attackCooldownTimer - deltaTime)
        }
        if attackComboTimer > 0 {
            attackComboTimer = max(0, attackComboTimer - deltaTime)
        } else {
            lastAttackAnimation = ""
        }

        pressedAttack = wantsAttack && isGrounded
        if pressedAttack {
            performAttack()
        }

        updateFacingDirection(inputAxis: inputAxis)

        velocity.dy -= GameConstants.gravity * gravityScale * GameConstants.pixelsPerUnit * dt
        velocity.dy = min(max(velocity.dy, -maxFallSpeed), jumpForce)
        let currentMoveSpeed = (pressedAttack || attacking) ? moveSpeedWhileAttacking : moveSpeed
        velocity.dx = inputAxis * currentMoveSpeed

        var newPosition = position
        newPosition.x += velocity.dx * dt
        newPosition.y += velocity.dy * dt

        // Simple AABB collision resolve
        let playerRect = hitboxRect(at: newPosition)
        isGrounded = false
        for rect in collisions {
            if playerRect.intersects(rect) {
                // Resolve only vertical first
                if position.y >= rect.maxY {
                    newPosition.y = rect.maxY + size.height / 2
                    velocity.dy = 0
                    isGrounded = true
                } else if position.y <= rect.minY {
                    newPosition.y = rect.minY - (hitboxHeight - size.height / 2)
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
        updateAnimationState(deltaTime: deltaTime, deltaPosition: delta)
        lastPosition = position
    }

    private func performAttack() {
        guard attackCooldownTimer <= 0 else {
            pressedAttack = false
            return
        }
        attackComboTimer = attackComboTimeframe
        attackCooldownTimer = attackCooldown
        attacking = true
        attackEffectNode.isHidden = false
        attackEffectNode.position = CGPoint(x: attackEffectOffset.dx, y: attackEffectOffset.dy)
        attackEffectAnimator?.play("attack", force: true) { [weak self] in
            self?.attackEffectNode.isHidden = true
        }
    }

    var isFacingRight: Bool {
        facingRight
    }

    var isAttacking: Bool {
        attacking
    }

    private func updateFacingDirection(inputAxis: CGFloat) {
        if inputAxis < -0.05, facingRight {
            setFacingDirection(false)
        } else if inputAxis > 0.05, !facingRight {
            setFacingDirection(true)
        }
    }

    private func setFacingDirection(_ facingRight: Bool) {
        guard self.facingRight != facingRight else { return }
        self.facingRight = facingRight
        xScale = facingRight ? 1 : -1
    }

    private func updateAnimationState(deltaTime: TimeInterval, deltaPosition: CGVector) {
        guard let animator else { return }

        let isMovingHorizontally = abs(deltaPosition.dx) > 0.01
        let isMovingVertically = abs(deltaPosition.dy) > 0.01

        if pressedAttack {
            let nextAnimation: String
            if animator.currentAnimation == "attack1", animator.isComplete {
                nextAnimation = "attack2"
            } else if animator.currentAnimation == "attack2", animator.isComplete {
                nextAnimation = "attack1"
            } else {
                nextAnimation = lastAttackAnimation == "attack1" ? "attack2" : "attack1"
            }
            lastAttackAnimation = nextAnimation
            animator.play(nextAnimation, force: true) { [weak self] in
                self?.attacking = false
            }
            return
        }

        if animator.currentAnimation == "attack1" || animator.currentAnimation == "attack2" {
            if animator.isComplete {
                animator.play("attackEnd", force: true)
                return
            }
        }

        if attacking {
            return
        }

        if isMovingVertically && !isGrounded {
            if deltaPosition.dy > 0 {
                if animator.currentAnimation != "jump" {
                    animator.play("jump")
                }
            } else if animator.currentAnimation != "fall" {
                animator.play("fall")
            }
            return
        }

        if isMovingHorizontally {
            if !isGrounded {
                return
            }
            switch animator.currentAnimation {
            case nil, "idle", "fall", "attackEnd":
                animator.play("walkStart")
            case "walkStart":
                if animator.isComplete {
                    animator.play("walkLoop")
                }
            case "walkEnd":
                animator.play(animator.isComplete ? "walkStart" : "walkLoop")
            default:
                animator.play("walkLoop")
            }
            return
        }

        switch animator.currentAnimation {
        case nil:
            playIdleAnimation(deltaTime: deltaTime)
        case "walkLoop":
            animator.play("walkEnd")
        case "walkStart":
            if animator.isComplete {
                playIdleAnimation(deltaTime: deltaTime)
            } else {
                animator.play("walkEnd")
            }
        case "fall":
            if isGrounded {
                animator.play("land")
            }
        default:
            if animator.isComplete {
                playIdleAnimation(deltaTime: deltaTime)
            }
        }
    }

    private func playIdleAnimation(deltaTime: TimeInterval) {
        idleAnimationTimer -= deltaTime
        if idleAnimationTimer <= 0 {
            animator?.play("idle")
            idleAnimationTimer = Double.random(in: 3.0...7.5)
        } else {
            texture = SKTexture(imageNamed: "Player1")
        }
    }

    var hitbox: CGRect {
        hitboxRect(at: position)
    }

    private func hitboxRect(at position: CGPoint) -> CGRect {
        let leftOffset = size.width - hitboxOffsetRight - hitboxWidth
        let offsetX = facingRight ? hitboxOffsetRight : leftOffset
        let originX = position.x - size.width / 2 + offsetX
        let originY = position.y - size.height / 2
        return CGRect(x: originX, y: originY, width: hitboxWidth, height: hitboxHeight)
    }
}

import SpriteKit

final class FlyeNode: SKSpriteNode, Entity {
    let isFriendly = false
    var health: Int = 6

    private let normalSpeed: CGFloat = 2.25
    private let pursuitSpeed: CGFloat = 2.5
    private let dashSpeed: CGFloat = 4.0
    private let verticalBiasRate: CGFloat = 4

    private let attackDelay: TimeInterval = 2.0
    private var attackTimer: TimeInterval = 0
    private var isAttacking = false

    private let staggerDuration: TimeInterval = 0.5
    private var staggerTimer: TimeInterval = 0

    // Abrupt knockback, used when the player hits the Flye.
    private let knockbackSpeed: CGFloat = 10
    private var knockbackTarget: CGPoint?

    // Smooth, eased recoil, triggered whenever the Flye touches the player.
    private let recoilDuration: TimeInterval = 0.5
    private let contactRecoilDistance: CGFloat = 330
    private var recoilStart: CGPoint = .zero
    private var recoilEnd: CGPoint = .zero
    private var recoilElapsed: TimeInterval = 0
    private var isRecoiling = false

    private var isPatrolling = false
    private var canPatrol = true
    private var isInPursuit = false
    private var hasReachedPlayerLastKnownPosition = true
    private var playerLastKnownPosition: CGPoint = .zero
    private var patrolDestination: CGPoint = .zero

    private var facingRight = true
    private var lastPosition: CGPoint = .zero
    private var colorLerpTimer: TimeInterval = 0
    private var didInitialize = false

    private let startPosition: CGPoint
    private let patrolArea: CGRect

    private weak var level: LevelScene?

    private let hitboxRadius: CGFloat = 160

    private let animationLibrary = try? AnimationLibrary.load(name: "flye")
    private lazy var animator: SpriteAnimator? = {
        guard let library = animationLibrary else { return nil }
        return SpriteAnimator(node: self, library: library)
    }()

    init(spawnPosition: CGPoint, level: LevelScene) {
        self.startPosition = spawnPosition
        self.level = level
        self.patrolArea = CGRect(
            x: spawnPosition.x - 1920,
            y: spawnPosition.y - 750,
            width: 3840,
            height: 1500
        )
        let texture = SKTexture(imageNamed: "Flye1")
        super.init(texture: texture, color: .white, size: texture.size())
        name = "Flye"
        anchorPoint = CGPoint(x: 299.5 / texture.size().width, y: 196 / texture.size().height)
        zPosition = GameConstants.layerEntities
        position = spawnPosition
        lastPosition = spawnPosition
        configurePhysicsBody()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configurePhysicsBody() {
        let body = SKPhysicsBody(circleOfRadius: hitboxRadius)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.linearDamping = 0
        body.categoryBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    var entityBounds: CGRect {
        CGRect(
            x: position.x - hitboxRadius,
            y: position.y - hitboxRadius,
            width: hitboxRadius * 2,
            height: hitboxRadius * 2
        )
    }

    func update(deltaTime: TimeInterval, player: PlayerNode) {
        if !didInitialize {
            didInitialize = true
            animator?.play("idle") { [weak self] in
                self?.canPatrol = true
            }
        }

        updateColorLerp(deltaTime: deltaTime)

        if isDead {
            return
        }

        if let target = knockbackTarget {
            let step = knockbackSpeed * GameConstants.pixelsPerUnit * CGFloat(deltaTime)
            position = position.moveTowards(target, maxDistance: step)
            if position.distance(to: target) < 1 {
                knockbackTarget = nil
            }
            return
        }

        if isRecoiling {
            updateRecoil(deltaTime: deltaTime)
            return
        }

        if staggerTimer > 0 {
            staggerTimer -= deltaTime
            return
        }

        if attackTimer > 0 {
            attackTimer -= deltaTime
        }

        let previousPosition = position

        checkForPlayer(deltaTime: deltaTime, player: player)

        if isAvailableToPatrol {
            startPatrol()
        } else if isPatrolling {
            if position.distance(to: patrolDestination) < 1 {
                isPatrolling = false
                animator?.play("patrol") { [weak self] in
                    self?.animator?.play("idle") { [weak self] in
                        self?.canPatrol = true
                    }
                }
            } else {
                moveTo(destination: patrolDestination, speed: normalSpeed * CGFloat(deltaTime))
            }
        }

        // Recoil away on every contact with the player (the hit itself is dealt by
        // the SKPhysicsContact → LevelScene.didBegin → PlayerNode.handleContactBegan).
        if !player.isDead,
           circleOverlapsRect(center: position, radius: hitboxRadius, rect: player.entityBounds) {
            beginContactRecoil(from: player)
        }

        if isInPursuit {
            guideAboveFloor(player, deltaTime: deltaTime)
            faceToward(player.position)
        } else {
            let delta = CGVector(dx: position.x - previousPosition.x, dy: position.y - previousPosition.y)
            updateFacingDirection(delta: delta)
        }
        lastPosition = position
    }

    private var isAvailableToPatrol: Bool {
        canPatrol && !isPatrolling && !isInPursuit
    }

    private func updateColorLerp(deltaTime: TimeInterval) {
        guard colorBlendFactor > 0.001 else {
            colorLerpTimer = 0
            return
        }
        colorLerpTimer = min(colorLerpTimer + deltaTime, 0.5)
        let factor = CGFloat(colorLerpTimer / 0.5)
        colorBlendFactor = max(0, 1 - factor)
    }

    private func startPatrol() {
        patrolDestination = CGPoint(
            x: CGFloat.random(in: patrolArea.minX...patrolArea.maxX),
            y: CGFloat.random(in: patrolArea.minY...patrolArea.maxY)
        )
        isPatrolling = true
        canPatrol = false
    }

    private func moveTo(destination: CGPoint, speed: CGFloat) {
        position = position.moveTowards(destination, maxDistance: speed * GameConstants.pixelsPerUnit)
        if animator?.currentAnimation != "move" {
            animator?.play("move")
        }
    }

    /// Lowest Y the Flye should settle at: the player's origin, which sits roughly
    /// at the player's middle.
    private func floorY(below player: PlayerNode) -> CGFloat {
        player.position.y
    }

    /// Smoothly biases the Flye up toward the floor line while engaged, rather than
    /// hard-clamping it — eases a fraction of the remaining gap each frame.
    private func guideAboveFloor(_ player: PlayerNode, deltaTime: TimeInterval) {
        let floor = floorY(below: player)
        guard position.y < floor else { return }
        let t = 1 - CGFloat(exp(-Double(verticalBiasRate) * deltaTime))
        position = CGPoint(x: position.x, y: position.y + (floor - position.y) * t)
    }

    /// Eased recoil away from the player on contact — gentler than the abrupt
    /// `knockbackTarget` used when the player strikes the Flye.
    private func updateRecoil(deltaTime: TimeInterval) {
        recoilElapsed += deltaTime
        let p = min(1, CGFloat(recoilElapsed / recoilDuration))
        let eased = p * p * (3 - 2 * p) // smoothstep (ease-in-out)
        position = recoilStart.lerp(to: recoilEnd, t: eased)
        if p >= 1 {
            isRecoiling = false
        }
    }

    private func checkForPlayer(deltaTime: TimeInterval, player: PlayerNode) {
        if player.isDead {
            isInPursuit = false
            canPatrol = true
            return
        }

        // Once a lunge is committed, see it through regardless of sight/range.
        if isAttacking {
            continueAttack(player: player, deltaTime: deltaTime)
            return
        }

        let playerBox = player.entityBounds
        var isPlayerInSight = sightCircleOverlaps(rect: playerBox)

        if isPlayerInSight {
            isPatrolling = false
            canPatrol = false
            hasReachedPlayerLastKnownPosition = false
            playerLastKnownPosition = player.position

            if !isInPursuit {
                animator?.play("alert") { [weak self] in
                    self?.isInPursuit = true
                }
            } else if attackTimer <= 0 && attackRangeOverlaps(rect: playerBox) {
                beginAttack(player: player, deltaTime: deltaTime)
            } else {
                // Closing in, or recovering between attacks: pursue the player.
                // Touching is handled by the recoil-on-contact in update().
                moveTo(destination: player.position, speed: pursuitSpeed * CGFloat(deltaTime))
            }
            return
        }

        if !hasReachedPlayerLastKnownPosition {
            isPatrolling = false
            isInPursuit = true
            moveTo(destination: playerLastKnownPosition, speed: pursuitSpeed * CGFloat(deltaTime))
            isPlayerInSight = sightCircleOverlaps(rect: playerBox)
            if isPlayerInSight {
                hasReachedPlayerLastKnownPosition = false
                playerLastKnownPosition = player.position
            } else if position.distance(to: playerLastKnownPosition) < 1 {
                hasReachedPlayerLastKnownPosition = true
            }
        }

        if isInPursuit && !isPlayerInSight {
            isInPursuit = false
            animator?.play("patrol") { [weak self] in
                self?.canPatrol = true
            }
        }
    }

    private func beginAttack(player: PlayerNode, deltaTime: TimeInterval) {
        isAttacking = true
        continueAttack(player: player, deltaTime: deltaTime)
    }

    private func continueAttack(player: PlayerNode, deltaTime: TimeInterval) {
        position = position.moveTowards(
            player.position,
            maxDistance: dashSpeed * GameConstants.pixelsPerUnit * CGFloat(deltaTime)
        )
        // A connecting lunge is closed out by beginContactRecoil; if it whiffs, end
        // it (and start the cooldown) when the animation finishes.
        animator?.play("attack") { [weak self] in
            guard let self, self.isAttacking else { return }
            self.endLunge()
        }
    }

    private func endLunge() {
        isAttacking = false
        attackTimer = attackDelay
    }

    /// Recoil away from the player on contact, easing out smoothly. If this happens
    /// mid-lunge, close out the lunge so the attack cooldown starts.
    private func beginContactRecoil(from player: PlayerNode) {
        let away = position - player.position
        let direction = away.length() > 1 ? away.normalized() : CGPoint(x: facingRight ? 1 : -1, y: 0)
        var end = position + direction * contactRecoilDistance
        end.y = max(end.y, floorY(below: player))

        recoilStart = position
        recoilEnd = end
        recoilElapsed = 0
        isRecoiling = true

        if isAttacking {
            endLunge()
        }
    }

    private func updateFacingDirection(delta: CGVector) {
        if facingRight && delta.dx < 0 {
            setFacing(right: false)
        } else if !facingRight && delta.dx > 0 {
            setFacing(right: true)
        }
    }

    private func setFacing(right: Bool) {
        guard facingRight != right else { return }
        facingRight = right
        xScale = right ? 1 : -1
    }

    private func faceToward(_ point: CGPoint) {
        if point.x < position.x {
            setFacing(right: false)
        } else if point.x > position.x {
            setFacing(right: true)
        }
    }

    private var sightCenter: CGPoint {
        CGPoint(x: position.x + (facingRight ? 200 : -200), y: position.y)
    }

    private var sightRadius: CGFloat {
        isPatrolling ? 700 : 1000
    }

    private func sightCircleOverlaps(rect: CGRect) -> Bool {
        circleOverlapsRect(center: sightCenter, radius: sightRadius, rect: rect)
    }

    private func attackRangeOverlaps(rect: CGRect) -> Bool {
        circleOverlapsRect(center: position, radius: 600, rect: rect)
    }

    private func circleOverlapsRect(center: CGPoint, radius: CGFloat, rect: CGRect) -> Bool {
        let closestX = max(rect.minX, min(center.x, rect.maxX))
        let closestY = max(rect.minY, min(center.y, rect.maxY))
        let dx = center.x - closestX
        let dy = center.y - closestY
        return dx * dx + dy * dy <= radius * radius
    }

    func takeDamage(source: SKNode?, amount: Int, impactForce: CGFloat) {
        guard !isDead else { return }
        health -= amount
        isAttacking = false
        isRecoiling = false
        color = .red
        colorBlendFactor = 1
        colorLerpTimer = 0

        if isDead {
            if let player = source as? PlayerNode {
                player.killCount += 1
            }
            animator?.play("death", force: true)
            physicsBody = nil
            return
        }

        if let src = source {
            let dir = (position - src.position).normalized()
            knockbackTarget = position + dir * impactForce * GameConstants.pixelsPerUnit
        }
        staggerTimer = staggerDuration
        animator?.play("idle", force: true)
    }

    func reset() {
        removeAllActions()
        position = startPosition
        lastPosition = startPosition
        health = 6
        isPatrolling = false
        canPatrol = true
        isInPursuit = false
        hasReachedPlayerLastKnownPosition = true
        attackTimer = 0
        isAttacking = false
        isRecoiling = false
        staggerTimer = 0
        knockbackTarget = nil
        colorBlendFactor = 0
        colorLerpTimer = 0
        didInitialize = false
        setFacing(right: true)
        if physicsBody == nil {
            configurePhysicsBody()
        }
    }

    func debugShapes() -> [(rect: CGRect, color: SKColor, isCircle: Bool, center: CGPoint, radius: CGFloat)] {
        guard !isDead else { return [] }
        return [
            (.zero, .red, true, position, hitboxRadius),
            (.zero, .yellow, true, sightCenter, sightRadius),
            (.zero, .green, true, position, 600),
            (patrolArea, .blue, false, .zero, 0)
        ]
    }
}

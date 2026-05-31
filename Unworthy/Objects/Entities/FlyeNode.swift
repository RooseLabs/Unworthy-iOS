import SpriteKit

final class FlyeNode: SKSpriteNode, Entity {
    let isFriendly = false
    var health: Int = 6

    private let normalSpeed: CGFloat = 2.25
    private let pursuitSpeed: CGFloat = 2.5
    private let dashSpeed: CGFloat = 4.0

    private let attackDelay: TimeInterval = 2.0
    private var attackTimer: TimeInterval = 0

    private let staggerDuration: TimeInterval = 0.5
    private var staggerTimer: TimeInterval = 0

    private let knockbackSpeed: CGFloat = 10
    private var knockbackTarget: CGPoint?

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

        if staggerTimer > 0 {
            staggerTimer -= deltaTime
            return
        }

        if attackTimer > 0 {
            attackTimer -= deltaTime
        }

        if !player.isDead && entityBounds.intersects(player.entityBounds) {
            player.takeDamage(source: self, amount: 1, impactForce: 0)
            applyPenetrationPush(against: player.entityBounds)
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

        let delta = CGVector(dx: position.x - previousPosition.x, dy: position.y - previousPosition.y)
        updateFacingDirection(delta: delta)
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

    private func checkForPlayer(deltaTime: TimeInterval, player: PlayerNode) {
        if player.isDead {
            isInPursuit = false
            canPatrol = true
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
            } else {
                if attackTimer <= 0 && attackRangeOverlaps(rect: playerBox) {
                    attack(targetPosition: player.position, deltaTime: deltaTime)
                } else {
                    moveTo(destination: player.position, speed: pursuitSpeed * CGFloat(deltaTime))
                }
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

    private func attack(targetPosition: CGPoint, deltaTime: TimeInterval) {
        position = position.moveTowards(
            targetPosition,
            maxDistance: dashSpeed * GameConstants.pixelsPerUnit * CGFloat(deltaTime)
        )
        animator?.play("attack") { [weak self] in
            guard let self else { return }
            self.attackTimer = self.attackDelay
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

    private func applyPenetrationPush(against rect: CGRect) {
        let closestX = max(rect.minX, min(position.x, rect.maxX))
        let closestY = max(rect.minY, min(position.y, rect.maxY))
        let dx = position.x - closestX
        let dy = position.y - closestY
        let distSq = dx * dx + dy * dy
        guard distSq < hitboxRadius * hitboxRadius else { return }
        if distSq == 0 {
            position = CGPoint(x: position.x, y: position.y - hitboxRadius)
            return
        }
        let dist = sqrt(distSq)
        let overlap = hitboxRadius - dist
        position = CGPoint(x: position.x + dx / dist * overlap, y: position.y + dy / dist * overlap)
    }

    func takeDamage(source: SKNode?, amount: Int, impactForce: CGFloat) {
        guard !isDead else { return }
        health -= amount
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
        health = 4
        isPatrolling = false
        canPatrol = true
        isInPursuit = false
        hasReachedPlayerLastKnownPosition = true
        attackTimer = 0
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

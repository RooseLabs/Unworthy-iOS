import SpriteKit

protocol Entity: AnyObject {
    var isFriendly: Bool { get }
    var health: Int { get set }
    var isDead: Bool { get }
    var entityBounds: CGRect { get }
    func takeDamage(source: SKNode?, amount: Int, impactForce: CGFloat)
}

extension Entity {
    var isDead: Bool { health <= 0 }
}

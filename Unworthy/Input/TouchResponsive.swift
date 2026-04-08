import SpriteKit

protocol TouchResponsive {
    func beginTouch(_ touch: UITouch, location: CGPoint)
    func moveTouch(_ touch: UITouch, location: CGPoint)
    func endTouch(_ touch: UITouch)
}

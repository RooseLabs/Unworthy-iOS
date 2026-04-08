import CoreGraphics

final class LevelInputState {
    var movementAxis: CGVector = .zero
    private var pendingJump = false
    private var attackPressed = false

    func setMovementAxis(_ axis: CGVector) {
        movementAxis = axis
    }

    func requestJump() {
        pendingJump = true
    }

    func consumeJumpRequest() -> Bool {
        defer { pendingJump = false }
        return pendingJump
    }

    func setAttackPressed(_ pressed: Bool) {
        attackPressed = pressed
    }

    var isAttackPressed: Bool {
        attackPressed
    }

    func reset() {
        movementAxis = .zero
        pendingJump = false
        attackPressed = false
    }
}

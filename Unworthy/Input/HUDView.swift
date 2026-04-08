import UIKit

final class HUDView: UIView {
    let inputState = LevelInputState()
    var onPauseRequested: (() -> Void)?

    private let analogControl = UIControlAnalog()
    private let attackButton = UIControlButton(
        imageNamed: "attack_button",
        style: .attack
    )
    private let jumpButton = UIControlButton(
        imageNamed: "jump_button",
        style: .jump
    )
    private let pauseButton = UIControlButton(
        imageNamed: "pause_button",
        style: .pause
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = true
        addSubview(analogControl)
        addSubview(attackButton)
        addSubview(jumpButton)
        addSubview(pauseButton)

        analogControl.onAxisChanged = { [weak inputState] axis in
            inputState?.setMovementAxis(axis)
        }

        jumpButton.onTouchDown = { [weak inputState] in
            inputState?.requestJump()
        }

        attackButton.onTouchStateChanged = { [weak inputState] isPressed in
            inputState?.setAttackPressed(isPressed)
        }

        pauseButton.onTouchUpInside = { [weak self] in
            self?.onPauseRequested?()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let safeRect = bounds.inset(by: safeAreaInsets)
        guard safeRect.width > 0, safeRect.height > 0 else { return }

        // Match Android HUD constants against 2160 target-height units.
        let analogDiameter = safeRect.height * (600.0 / 2160.0)
        let actionDiameter = safeRect.height * (350.0 / 2160.0)
        let pauseDiameter = safeRect.height * (160.0 / 2160.0)

        analogControl.bounds = CGRect(x: 0, y: 0, width: analogDiameter, height: analogDiameter)
        attackButton.bounds = CGRect(x: 0, y: 0, width: actionDiameter, height: actionDiameter)
        jumpButton.bounds = CGRect(x: 0, y: 0, width: actionDiameter, height: actionDiameter)
        pauseButton.bounds = CGRect(x: 0, y: 0, width: pauseDiameter, height: pauseDiameter)

        place(analogControl, anchorX: 0.15, anchorY: 0.225, in: safeRect)
        place(attackButton, anchorX: 0.825, anchorY: 0.155, in: safeRect)
        place(jumpButton, anchorX: 0.925, anchorY: 0.275, in: safeRect)
        place(pauseButton, anchorX: 0.95, anchorY: 0.925, in: safeRect)
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }
        let hitView = super.hitTest(point, with: event)
        return hitView === self ? nil : hitView
    }

    func configureForLevel() {
        isHidden = false
        analogControl.reset()
        inputState.setMovementAxis(.zero)
        inputState.setAttackPressed(false)
        _ = inputState.consumeJumpRequest()
    }

    func configureForMenu() {
        isHidden = true
        analogControl.reset()
        inputState.setMovementAxis(.zero)
        inputState.setAttackPressed(false)
        _ = inputState.consumeJumpRequest()
    }

    private func place(_ view: UIView, anchorX: CGFloat, anchorY: CGFloat, in safeRect: CGRect) {
        let centerX = safeRect.minX + anchorX * safeRect.width
        let centerY = safeRect.maxY - anchorY * safeRect.height
        let halfWidth = view.bounds.width / 2
        let halfHeight = view.bounds.height / 2
        let clampedX = min(max(centerX, safeRect.minX + halfWidth), safeRect.maxX - halfWidth)
        let clampedY = min(max(centerY, safeRect.minY + halfHeight), safeRect.maxY - halfHeight)
        view.center = CGPoint(x: clampedX, y: clampedY)
    }

}

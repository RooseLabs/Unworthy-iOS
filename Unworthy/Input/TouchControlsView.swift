import UIKit

final class TouchControlsView: UIView {
    let inputState = LevelInputState()
    var onPauseRequested: (() -> Void)?
    var onTouchInteraction: (() -> Void)?

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

        analogControl.onAxisChanged = { [weak self] axis in
            self?.inputState.setMovementAxis(axis)
            self?.onTouchInteraction?()
        }

        jumpButton.onTouchDown = { [weak self] in
            self?.inputState.requestJump()
            self?.onTouchInteraction?()
        }

        attackButton.onTouchDown = { [weak self] in
            self?.inputState.requestAttack()
            self?.onTouchInteraction?()
        }

        attackButton.onTouchStateChanged = { [weak self] isPressed in
            self?.inputState.setAttackPressed(isPressed)
            if isPressed { self?.onTouchInteraction?() }
        }

        pauseButton.onTouchUpInside = { [weak self] in
            self?.onTouchInteraction?()
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

        let referenceAspect: CGFloat = GameConstants.targetWidth / GameConstants.targetHeight
        let unit = (safeRect.width * safeRect.height / referenceAspect).squareRoot()

        let analogDiameter = unit * 0.311
        let actionDiameter = unit * 0.160
        let pauseDiameter = unit * 0.080

        analogControl.bounds = CGRect(x: 0, y: 0, width: analogDiameter, height: analogDiameter)
        attackButton.bounds = CGRect(x: 0, y: 0, width: actionDiameter, height: actionDiameter)
        jumpButton.bounds = CGRect(x: 0, y: 0, width: actionDiameter, height: actionDiameter)
        pauseButton.bounds = CGRect(x: 0, y: 0, width: pauseDiameter, height: pauseDiameter)

        place(analogControl, fromLeft: 0.213 * unit, fromBottom: 0.20 * unit, in: safeRect)
        place(attackButton, fromRight: 0.311 * unit, fromBottom: 0.155 * unit, in: safeRect)
        place(jumpButton, fromRight: 0.133 * unit, fromBottom: 0.275 * unit, in: safeRect)
        place(pauseButton, fromRight: 0.089 * unit, fromTop: 0.075 * unit, in: safeRect)
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
        _ = inputState.consumeAttackRequest()
    }

    func configureForMenu() {
        isHidden = true
        analogControl.reset()
        inputState.setMovementAxis(.zero)
        inputState.setAttackPressed(false)
        _ = inputState.consumeJumpRequest()
        _ = inputState.consumeAttackRequest()
    }

    private func place(
        _ view: UIView,
        fromLeft leftMargin: CGFloat? = nil,
        fromRight rightMargin: CGFloat? = nil,
        fromBottom bottomMargin: CGFloat? = nil,
        fromTop topMargin: CGFloat? = nil,
        in safeRect: CGRect
    ) {
        let centerX: CGFloat
        if let leftMargin {
            centerX = safeRect.minX + leftMargin
        } else if let rightMargin {
            centerX = safeRect.maxX - rightMargin
        } else {
            centerX = safeRect.midX
        }

        let centerY: CGFloat
        if let bottomMargin {
            centerY = safeRect.maxY - bottomMargin
        } else if let topMargin {
            centerY = safeRect.minY + topMargin
        } else {
            centerY = safeRect.midY
        }

        let halfWidth = view.bounds.width / 2
        let halfHeight = view.bounds.height / 2
        let clampedX = min(max(centerX, safeRect.minX + halfWidth), safeRect.maxX - halfWidth)
        let clampedY = min(max(centerY, safeRect.minY + halfHeight), safeRect.maxY - halfHeight)
        view.center = CGPoint(x: clampedX, y: clampedY)
    }

}

import UIKit

final class LevelHUDOverlayView: UIView {
    let inputState = LevelInputState()
    var onPauseRequested: (() -> Void)?

    private let analogControl = AnalogStickControlView()
    private let attackButton = CircularHUDButtonView(
        imageNamed: "attack_button",
        style: .attack
    )
    private let jumpButton = CircularHUDButtonView(
        imageNamed: "jump_button",
        style: .jump
    )
    private let pauseButton = CircularHUDButtonView(
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

final class AnalogStickControlView: UIView {
    var onAxisChanged: ((CGVector) -> Void)?

    private let ringView = UIView()
    private let knobView = UIView()
    private var trackingTouch: UITouch?
    private var travelRadius: CGFloat = 1
    private var touchRadius: CGFloat = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = true

        ringView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        ringView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        addSubview(ringView)

        knobView.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        knobView.isHidden = true
        addSubview(knobView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        ringView.frame = bounds
        ringView.layer.cornerRadius = bounds.width / 2

        let knobDiameter = bounds.width * 0.25
        knobView.bounds = CGRect(x: 0, y: 0, width: knobDiameter, height: knobDiameter)
        knobView.layer.cornerRadius = knobDiameter / 2

        travelRadius = max(1, bounds.width * 0.5)
        touchRadius = max(travelRadius, travelRadius * 2.5)
        if trackingTouch == nil {
            knobView.center = CGPoint(x: bounds.midX, y: bounds.midY)
            knobView.isHidden = true
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let center = bounds.center
        let dx = point.x - center.x
        let dy = point.y - center.y
        return dx * dx + dy * dy <= touchRadius * touchRadius
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackingTouch == nil, let touch = touches.first else { return }
        let location = touch.location(in: self)
        guard distance(from: location, to: bounds.center) <= touchRadius else { return }
        trackingTouch = touch
        knobView.isHidden = false
        updateKnob(for: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let trackingTouch, touches.contains(trackingTouch) else { return }
        updateKnob(for: trackingTouch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let trackingTouch, touches.contains(trackingTouch) else {
            self.trackingTouch = nil
            return
        }
        reset(animated: true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let trackingTouch, touches.contains(trackingTouch) else {
            self.trackingTouch = nil
            return
        }
        reset(animated: true)
    }

    func reset(animated: Bool = false) {
        trackingTouch = nil
        onAxisChanged?(CGVector.zero)

        let target = CGPoint(x: bounds.midX, y: bounds.midY)
        knobView.center = target
        knobView.isHidden = true
    }

    private func updateKnob(for location: CGPoint) {
        let center = bounds.center
        let offset = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        let length = max(0.001, sqrt(offset.dx * offset.dx + offset.dy * offset.dy))
        let clampedLength = min(length, travelRadius)
        let normalized = CGVector(dx: offset.dx / length, dy: offset.dy / length)
        let clampedOffset = CGVector(dx: normalized.dx * clampedLength, dy: normalized.dy * clampedLength)
        knobView.center = CGPoint(x: center.x + clampedOffset.dx, y: center.y + clampedOffset.dy)
        onAxisChanged?(CGVector(dx: clampedOffset.dx / travelRadius, dy: clampedOffset.dy / travelRadius))
    }

    private func distance(from point: CGPoint, to other: CGPoint) -> CGFloat {
        let dx = point.x - other.x
        let dy = point.y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

final class CircularHUDButtonView: UIControl {
    var onTouchDown: (() -> Void)?
    var onTouchUpInside: (() -> Void)?
    var onTouchStateChanged: ((Bool) -> Void)?

    private let backgroundView = UIView()
    private let imageView = UIImageView()
    private var trackingTouch: UITouch?
    private let style: Style

    struct Style {
        let normalFill: UIColor
        let pressedFill: UIColor
        let normalTint: UIColor
        let pressedTint: UIColor

        static let jump = Style(
            normalFill: UIColor.black.withAlphaComponent(0.25),
            pressedFill: UIColor.white.withAlphaComponent(0.10),
            normalTint: UIColor.white,
            pressedTint: UIColor.white
        )

        static let attack = Style(
            normalFill: UIColor.black.withAlphaComponent(0.25),
            pressedFill: UIColor.white.withAlphaComponent(0.10),
            normalTint: UIColor.white,
            pressedTint: UIColor.white
        )

        static let pause = Style(
            normalFill: UIColor.black.withAlphaComponent(0.25),
            pressedFill: UIColor.black.withAlphaComponent(0.25),
            normalTint: UIColor.white,
            pressedTint: UIColor(red: 0xDD / 255.0, green: 0x10 / 255.0, blue: 0x0E / 255.0, alpha: 1.0)
        )
    }

    init(imageNamed name: String, style: Style) {
        self.style = style
        super.init(frame: .zero)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        clipsToBounds = false

        backgroundView.backgroundColor = style.normalFill
        addSubview(backgroundView)

        imageView.image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = style.normalTint
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = bounds
        backgroundView.layer.cornerRadius = bounds.width / 2

        let iconInset = bounds.width * 0.22
        imageView.frame = bounds.insetBy(dx: iconInset, dy: iconInset)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hitInset = bounds.width * 0.12
        let expandedBounds = bounds.insetBy(dx: -hitInset, dy: -hitInset)
        return expandedBounds.contains(point)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackingTouch == nil, let touch = touches.first else { return }
        guard point(inside: touch.location(in: self), with: event) else { return }
        trackingTouch = touch
        setPressed(true)
        onTouchDown?()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let trackingTouch, touches.contains(trackingTouch) else { return }
        let inside = point(inside: trackingTouch.location(in: self), with: event)
        setPressed(inside)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let trackingTouch, touches.contains(trackingTouch) else {
            self.trackingTouch = nil
            return
        }
        let inside = point(inside: trackingTouch.location(in: self), with: event)
        setPressed(false)
        if inside {
            onTouchUpInside?()
        }
        self.trackingTouch = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let trackingTouch, touches.contains(trackingTouch) else {
            self.trackingTouch = nil
            return
        }
        setPressed(false)
        self.trackingTouch = nil
    }

    private func setPressed(_ pressed: Bool) {
        backgroundView.backgroundColor = pressed ? style.pressedFill : style.normalFill
        imageView.tintColor = pressed ? style.pressedTint : style.normalTint
        onTouchStateChanged?(pressed)
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

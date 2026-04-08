import UIKit

final class UIControlButton: UIControl {
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

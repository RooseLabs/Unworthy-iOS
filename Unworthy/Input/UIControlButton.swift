import UIKit

final class UIControlButton: UIControl {
    var onTouchDown: (() -> Void)?
    var onTouchUpInside: (() -> Void)?
    var onTouchStateChanged: ((Bool) -> Void)?

    private let backgroundView = UIView()
    private let imageView = UIImageView()
    private var trackingTouch: UITouch?
    private let style: Style
    private let normalImage: UIImage?
    private let pressedImage: UIImage?

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
            pressedTint: UIColor(red: 0.87, green: 0.06, blue: 0.05, alpha: 1.0)
        )
    }

    init(imageNamed name: String, style: Style) {
        self.style = style
        let source = UIImage(named: name)
        self.normalImage = source?.multiplyTinted(style.normalTint)
        self.pressedImage = source?.multiplyTinted(style.pressedTint)
        super.init(frame: .zero)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        clipsToBounds = false

        backgroundView.backgroundColor = style.normalFill
        addSubview(backgroundView)

        imageView.image = normalImage
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

        let iconInset = bounds.width * 0.05
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
        imageView.image = pressed ? pressedImage : normalImage
        onTouchStateChanged?(pressed)
    }
}

private extension UIImage {
    func multiplyTinted(_ color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            draw(in: rect)
            color.setFill()
            ctx.cgContext.setBlendMode(.multiply)
            ctx.cgContext.fill(rect)
            // Re-apply the original alpha so the tint doesn't bleed past transparent pixels.
            draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
    }
}

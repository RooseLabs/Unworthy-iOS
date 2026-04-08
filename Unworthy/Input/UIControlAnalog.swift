import UIKit

final class UIControlAnalog: UIView {
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
        reset()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let trackingTouch, touches.contains(trackingTouch) else {
            self.trackingTouch = nil
            return
        }
        reset()
    }

    func reset() {
        trackingTouch = nil
        onAxisChanged?(CGVector.zero)
        knobView.center = CGPoint(x: bounds.midX, y: bounds.midY)
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

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

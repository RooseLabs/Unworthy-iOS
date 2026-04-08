import SpriteKit
import CoreGraphics

final class StarsNode: SKNode {
    private let layer1A: SKSpriteNode
    private let layer1B: SKSpriteNode
    private let layer2A: SKSpriteNode
    private let layer2B: SKSpriteNode

    private let speed1: CGFloat = -20.0
    private let speed2: CGFloat = -28.0

    private static let minRadius = 3
    private static let maxRadius = 8
    private static let minDistance: CGFloat = 25
    private static let numberOfStars = 80

    init(size: CGSize) {
        let texture1 = SKTexture(cgImage: Self.makeStarsImage(size: size))
        let texture2 = SKTexture(cgImage: Self.makeStarsImage(size: size))
        texture1.filteringMode = .nearest
        texture2.filteringMode = .nearest

        layer1A = SKSpriteNode(texture: texture1)
        layer1B = SKSpriteNode(texture: texture1)
        layer2A = SKSpriteNode(texture: texture2)
        layer2B = SKSpriteNode(texture: texture2)

        super.init()

        setupLayer(layer1A, size: size, y: 0)
        setupLayer(layer1B, size: size, y: size.height)
        setupLayer(layer2A, size: size, y: 0)
        setupLayer(layer2B, size: size, y: size.height)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    private func setupLayer(_ layer: SKSpriteNode, size: CGSize, y: CGFloat) {
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: 0, y: y)
        layer.size = size
        layer.blendMode = .alpha
        addChild(layer)
    }

    func update(deltaTime: TimeInterval, size: CGSize) {
        let dy1 = speed1 * CGFloat(deltaTime)
        let dy2 = speed2 * CGFloat(deltaTime)

        layer1A.position.y -= dy1
        layer1B.position.y -= dy1
        layer2A.position.y -= dy2
        layer2B.position.y -= dy2

        wrapPair(layer1A, layer1B, size: size)
        wrapPair(layer2A, layer2B, size: size)
    }

    private func wrapPair(_ first: SKSpriteNode, _ second: SKSpriteNode, size: CGSize) {
        let threshold = size.height
        let span = size.height * 2

        if first.position.y >= threshold {
            first.position.y -= span
        }
        if second.position.y >= threshold {
            second.position.y -= span
        }
    }

    private static func makeStarsImage(size: CGSize) -> CGImage {
        let width = max(Int(size.width), 1)
        let height = max(Int(size.height), 1)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            // Fallback 1x1 transparent image
            let fallback = CGContext(
                data: nil,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            return fallback.makeImage()!
        }

        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))

        var starPositions: [CGPoint] = []
        starPositions.reserveCapacity(numberOfStars)

        var attempts = 0
        let maxAttempts = numberOfStars * 80

        while starPositions.count < numberOfStars && attempts < maxAttempts {
            attempts += 1
            let x = CGFloat.random(in: 0 ..< CGFloat(width))
            let y = CGFloat.random(in: 0 ..< CGFloat(height))
            let candidate = CGPoint(x: x, y: y)

            let tooClose = starPositions.contains { existing in
                let dx = existing.x - candidate.x
                let dy = existing.y - candidate.y
                return sqrt(dx * dx + dy * dy) < minDistance
            }
            if tooClose { continue }

            let radius = CGFloat(Int.random(in: minRadius ... maxRadius))
            let rect = CGRect(x: candidate.x - radius, y: candidate.y - radius, width: radius * 2, height: radius * 2)
            context.fillEllipse(in: rect)
            starPositions.append(candidate)
        }

        if let image = context.makeImage() {
            return image
        }

        let fallback = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return fallback.makeImage()!
    }
}

import SpriteKit
import CoreGraphics

final class StarsNode: SKNode {
    private let worldSize: CGSize
    private let textureSize = CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight)
    private let tilesX: Int
    private let tilesY: Int

    private let layer1Node = SKNode()
    private let layer2Node = SKNode()
    private var layer1Tiles: [SKSpriteNode] = []
    private var layer2Tiles: [SKSpriteNode] = []

    private let speed1: CGFloat = 0.05 * GameConstants.pixelsPerUnit
    private let speed2: CGFloat = 0.1 * GameConstants.pixelsPerUnit
    private var layer1OffsetY: CGFloat = 0
    private var layer2OffsetY: CGFloat = 0

    private static let minRadius = 3
    private static let maxRadius = 8
    private static let minDistance: CGFloat = 25
    private static let numberOfStars = 80
    private static var cachedLayer1Texture: SKTexture?
    private static var cachedLayer2Texture: SKTexture?

    init(size: CGSize) {
        worldSize = size
        tilesX = Int(ceil(size.width / GameConstants.targetWidth)) + 1
        tilesY = Int(ceil(size.height / GameConstants.targetHeight)) + 1

        let texture1: SKTexture
        if let cached = Self.cachedLayer1Texture {
            texture1 = cached
        } else {
            let generated = SKTexture(cgImage: Self.makeStarsImage(size: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight)))
            generated.filteringMode = .nearest
            Self.cachedLayer1Texture = generated
            texture1 = generated
        }

        let texture2: SKTexture
        if let cached = Self.cachedLayer2Texture {
            texture2 = cached
        } else {
            let generated = SKTexture(cgImage: Self.makeStarsImage(size: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight)))
            generated.filteringMode = .nearest
            Self.cachedLayer2Texture = generated
            texture2 = generated
        }

        texture1.filteringMode = .nearest
        texture2.filteringMode = .nearest

        super.init()

        addChild(layer1Node)
        addChild(layer2Node)

        layer1Tiles = createTiles(texture: texture1, in: layer1Node)
        layer2Tiles = createTiles(texture: texture2, in: layer2Node)
        layoutTiles(layer1Tiles, offsetY: layer1OffsetY)
        layoutTiles(layer2Tiles, offsetY: layer2OffsetY)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    private func createTiles(texture: SKTexture, in parent: SKNode) -> [SKSpriteNode] {
        var tiles: [SKSpriteNode] = []
        tiles.reserveCapacity(tilesX * tilesY)

        for _ in 0 ..< (tilesX * tilesY) {
            let tile = SKSpriteNode(texture: texture)
            tile.anchorPoint = .zero
            tile.size = textureSize
            tile.blendMode = .alpha
            parent.addChild(tile)
            tiles.append(tile)
        }

        return tiles
    }

    func update(deltaTime: TimeInterval) {
        layer1OffsetY = wrapped(layer1OffsetY + speed1 * CGFloat(deltaTime), period: textureSize.height)
        layer2OffsetY = wrapped(layer2OffsetY + speed2 * CGFloat(deltaTime), period: textureSize.height)

        layoutTiles(layer1Tiles, offsetY: layer1OffsetY)
        layoutTiles(layer2Tiles, offsetY: layer2OffsetY)
    }

    private func layoutTiles(_ tiles: [SKSpriteNode], offsetY: CGFloat) {
        let startX = -textureSize.width
        let startY = wrapped(offsetY, period: textureSize.height) - textureSize.height

        var index = 0
        for i in 0 ..< tilesX {
            for j in 0 ..< tilesY {
                tiles[index].position = CGPoint(
                    x: startX + CGFloat(i) * textureSize.width,
                    y: startY + CGFloat(j) * textureSize.height
                )
                index += 1
            }
        }
    }

    private func wrapped(_ value: CGFloat, period: CGFloat) -> CGFloat {
        guard period > 0 else { return value }
        let remainder = value.truncatingRemainder(dividingBy: period)
        return remainder >= 0 ? remainder : remainder + period
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

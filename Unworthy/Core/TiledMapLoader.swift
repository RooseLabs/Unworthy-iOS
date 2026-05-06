import Foundation
import SpriteKit
import CoreGraphics

final class TiledMapLoader {
    let map: TiledMap

    private let rectangleTypes: Set<String> = [
        "Ground",
        "Platform",
        "Boundary",
        "CameraBounds",
        "Stars",
        "KillTrigger"
    ]

    private let typeToAsset: [String: String] = AssetProvider.tiledToTexture

    private let typeToOrigin: [String: CGPoint] = [
        "Player": CGPoint(x: 131.84, y: 152),
        "Flye": CGPoint(x: 299.5, y: 196)
    ]

    init(mapName: String, bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "Maps/\(mapName)", withExtension: "tmj") ?? bundle.url(forResource: mapName, withExtension: "tmj") else {
            throw NSError(domain: "TiledMapLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing map file: \(mapName).tmj"])
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        map = try decoder.decode(TiledMap.self, from: data)
    }

    func layers(named name: String) -> [TiledLayer] {
        map.layers.filter { $0.name == name }
    }

    func objects(in layerName: String) -> [TiledObject] {
        layers(named: layerName).flatMap { $0.objects ?? [] }
    }

    func rectangles(ofType type: String, in layerName: String) -> [CGRect] {
        objects(in: layerName).filter { $0.type == type }.map { rect(for: $0) }
    }

    func rect(for object: TiledObject) -> CGRect {
        var y = -object.y
        if rectangleTypes.contains(object.type) {
            y -= object.height
        }
        return CGRect(x: object.x, y: y, width: object.width, height: object.height)
    }

    func position(for object: TiledObject) -> CGPoint {
        if let origin = typeToOrigin[object.type] {
            return CGPoint(x: object.x + origin.x, y: -object.y - origin.y)
        }
        if rectangleTypes.contains(object.type) {
            let rect = rect(for: object)
            return rect.origin
        }
        let centerX = object.x + object.width / 2
        let y = -object.y + object.height / 2
        return CGPoint(x: centerX, y: y)
    }

    func isFlippedHorizontally(_ object: TiledObject) -> Bool {
        guard let properties = object.properties else { return false }
        return properties.contains { property in
            property.name == "FlipX" &&
            ((property.value.boolValue ?? false) || property.value.stringValue == "true")
        }
    }

    func assetPath(for object: TiledObject) -> String? {
        typeToAsset[object.type]
    }
}

private extension TiledPropertyValue {
    var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        switch self {
        case let .bool(value): return value
        case let .string(value): return Bool(value)
        default: return nil
        }
    }
}

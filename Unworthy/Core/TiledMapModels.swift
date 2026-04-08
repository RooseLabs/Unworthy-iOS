import Foundation
import CoreGraphics

struct TiledMap: Decodable {
    let height: Int?
    let width: Int?
    let infinite: Bool
    let layers: [TiledLayer]
}

enum TiledLayerType: String, Decodable {
    case tilelayer
    case objectgroup
}

struct TiledLayer: Decodable {
    let id: Int
    let name: String
    let type: TiledLayerType
    let draworder: String?
    let opacity: Double?
    let visible: Bool
    let objects: [TiledObject]?
}

struct TiledObject: Decodable {
    let id: Int
    let name: String
    let type: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let rotation: CGFloat?
    let visible: Bool?
    let gid: Int?
    let properties: [TiledProperty]?
}

struct TiledProperty: Decodable {
    let name: String
    let type: String?
    let value: TiledPropertyValue
}

enum TiledPropertyValue: Decodable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case double(Double)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported property type")
        }
    }
}

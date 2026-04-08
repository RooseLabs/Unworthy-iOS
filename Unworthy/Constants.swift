import CoreGraphics

enum GameConstants {
    static let targetWidth: CGFloat = 3840
    static let targetHeight: CGFloat = 2160
    static let pixelsPerUnit: CGFloat = 330
    static let gravity: CGFloat = 9.81

    static let layerBackground0: CGFloat = 0.0
    static let layerBackground1: CGFloat = 0.1
    static let layerGround: CGFloat = 0.2
    static let layerPlatforms: CGFloat = 0.3
    static let layerBackground2: CGFloat = 0.4
    static let layerObjects: CGFloat = 0.5
    static let layerEntities: CGFloat = 0.6
    static let layerForeground: CGFloat = 0.7
    static let layerVignette: CGFloat = 0.8
    static let layerUI: CGFloat = 0.9
}

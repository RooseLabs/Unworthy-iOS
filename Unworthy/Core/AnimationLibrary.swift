import Foundation
import SpriteKit

struct AnimationCycleDefinition: Decodable {
    let frames: [Int]
    let isLooping: Bool
    let isReversed: Bool?
    let frameRate: Double
}

struct TextureAtlasDefinition: Decodable {
    let frameBaseName: String
    let indexStartsAt: Int?
}

struct AnimationDefinition: Decodable {
    let textureAtlas: TextureAtlasDefinition
    let cycles: [String: AnimationCycleDefinition]
}

struct AnimationClip {
    let name: String
    let textures: [SKTexture]
    let isLooping: Bool
    let isReversed: Bool
    let frameRate: Double
}

final class AnimationLibrary {
    private let clips: [String: AnimationClip]

    init(definition: AnimationDefinition) {
        let atlas = definition.textureAtlas
        let startIndexValue = atlas.indexStartsAt ?? 0
        let baseName = atlas.frameBaseName
        var built: [String: AnimationClip] = [:]
        for (name, cycle) in definition.cycles {
            let textures = cycle.frames.compactMap { frameIndex -> SKTexture? in
                let frameNumber = frameIndex + startIndexValue
                let textureName = "\(baseName)\(frameNumber)"
                return SKTexture(imageNamed: textureName)
            }
            built[name] = AnimationClip(
                name: name,
                textures: textures,
                isLooping: cycle.isLooping,
                isReversed: cycle.isReversed ?? false,
                frameRate: cycle.frameRate
            )
        }
        clips = built
    }

    static func load(name: String, bundle: Bundle = .main) throws -> AnimationLibrary {
        let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Assets/Animations")
            ?? bundle.url(forResource: name, withExtension: "json")
        guard let resolvedUrl = url else {
            throw NSError(domain: "AnimationLibrary", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing animation file \(name).json"])
        }
        let data = try Data(contentsOf: resolvedUrl)
        let definition = try JSONDecoder().decode(AnimationDefinition.self, from: data)
        return AnimationLibrary(definition: definition)
    }

    func action(for name: String) -> SKAction? {
        guard let clip = clips[name] else { return nil }
        var frames = clip.textures
        if clip.isReversed {
            frames = frames.reversed()
        }
        if frames.isEmpty { return nil }

        let timePerFrame = 1.0 / clip.frameRate
        let forwardAction = SKAction.animate(with: frames, timePerFrame: timePerFrame, resize: false, restore: false)

        if clip.isLooping {
            return SKAction.repeatForever(forwardAction)
        }
        return forwardAction
    }

    func firstTexture() -> SKTexture? {
        return clips.values.first?.textures.first
    }

    func isLooping(_ name: String) -> Bool {
        return clips[name]?.isLooping ?? false
    }
}

final class SpriteAnimator {
    private weak var node: SKSpriteNode?
    private let library: AnimationLibrary
    private(set) var currentAnimation: String?

    init(node: SKSpriteNode, library: AnimationLibrary) {
        self.node = node
        self.library = library
    }

    func play(_ name: String, force: Bool = false, completion: (() -> Void)? = nil) {
        guard let node else { return }
        if !force && currentAnimation == name { return }
        guard let action = library.action(for: name) else { return }
        currentAnimation = name
        node.removeAction(forKey: "animation")
        if library.isLooping(name) {
            node.run(action, withKey: "animation")
            completion?()
        } else {
            node.run(SKAction.sequence([action, .run { [weak self] in
                self?.currentAnimation = nil
                completion?()
            }]), withKey: "animation")
        }
    }
}

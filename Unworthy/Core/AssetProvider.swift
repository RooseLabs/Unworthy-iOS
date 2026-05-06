import SpriteKit
import AVFoundation

final class AssetProvider {
    static let Instance = AssetProvider()

    private let bundle = Bundle.main
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var cachedTextures: [String: SKTexture] = [:]

    private init() {}

    // MARK: - Texture Loading

    /// Load a texture by logical key. Returns nil if not found.
    func texture(for key: String) -> SKTexture? {
        if let cached = cachedTextures[key] {
            return cached
        }

        let texture = SKTexture(imageNamed: key)
        // SKTexture will be empty if not found, so we cache regardless
        cachedTextures[key] = texture
        return texture
    }

    /// Preload an array of textures for faster runtime access.
    func preloadTextures(_ keys: [String]) {
        let textures = keys.compactMap { texture(for: $0) }
        SKTexture.preload(textures) { }
    }

    // MARK: - Asset Key Mapping

    /// Map Tiled object types to texture keys for xcassets access.
    /// These keys work directly with SKTexture(imageNamed:) for xcassets images.
    static let tiledToTexture: [String: String] = [
        // Background objects
        "CloudsUp": "clouds_up",
        "CloudsDown": "clouds_down",
        "CloudsUpEnd": "clouds_up_end",
        "CloudsDownEnd": "clouds_down_end",
        "TreesFront": "trees_front",
        "TreesBack": "trees_back",
        "CityLimits": "city_limits",
        "CityForest": "city_forest",
        "City1": "city1",
        "City2": "city2",
        "City3": "city3",
        "Figures": "figures",

        // Object platform types
        "RockPlatform": "small_platform",
        "LargeRockPlatform": "large_platform",
        "Door": "door",
        "BossHouse": "boss_house",
        "Spikes": "spikes",
    ]

    /// UI assets - these are in the UI.spriteatlas
    static let uiAssets: [String: String] = [
        "title": "title",
        "character_fall": "character_fall",
        "taptobegin": "taptobegin",
        "jump_button": "jump_button",
        "attack_button": "attack_button",
        "pause_button": "pause_button",
        "life_clock": "life_clock",
    ]

    // MARK: - Audio Loading

    /// Load and play background music by filename from bundle resources.
    /// Accepts either "name" or "name.m4a" and resolves from root or Sounds/.
    func playBackgroundMusic(named filename: String) {
        // Stop any existing BGM before replacing it.
        stopBackgroundMusic()

        let nsName = filename as NSString
        let ext = nsName.pathExtension.lowercased()
        let baseName = nsName.deletingPathExtension

        // Project standard is m4a; treat extensionless names as m4a.
        let resourceName = ext.isEmpty ? filename : baseName
        let resourceExt = ext.isEmpty ? "m4a" : ext

        let url = bundle.url(forResource: resourceName, withExtension: resourceExt)
            ?? bundle.url(forResource: "Sounds/\(resourceName)", withExtension: resourceExt)

        guard let url else {
            print("Background music file not found in bundle: \(filename)")
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = -1
            audioPlayer.volume = 0.5
            audioPlayer.play()
            audioPlayers["bgm"] = audioPlayer
        } catch {
            print("Error loading background music \(filename): \(error)")
        }
    }

    /// Stop background music.
    func stopBackgroundMusic() {
        audioPlayers["bgm"]?.stop()
        audioPlayers.removeValue(forKey: "bgm")
    }

    // MARK: - Preload Groups

    /// Preload all assets needed for the main menu.
    func preloadMainMenuAssets() {
        let menuTextures = [
            "title",
            "character_fall",
            "taptobegin",
        ]
        preloadTextures(menuTextures)
    }

    /// Preload all assets needed for the level scene.
    func preloadLevelAssets() {
        let levelTextures = [
            // UI buttons
            "jump_button",
            "attack_button",
            "pause_button",
            "life_clock",
            // Objects
            "small_platform",
            "large_platform",
            "door",
            "boss_house",
            "spikes",
            // Vignette
            "vignette",
        ]
        preloadTextures(levelTextures)
    }
}

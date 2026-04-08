import SpriteKit

protocol CoordinatedScene {
    var coordinator: SceneCoordinator? { get set }
}

protocol SceneScaleModeProviding {
    var preferredScaleMode: SKSceneScaleMode { get }
}

extension SceneScaleModeProviding {
    var preferredScaleMode: SKSceneScaleMode { .aspectFill }
}

protocol SceneCoordinatorDelegate: AnyObject {
    func sceneCoordinator(_ coordinator: SceneCoordinator, willPresent scene: SKScene)
}

final class SceneCoordinator {
    private weak var view: SKView?
    weak var delegate: SceneCoordinatorDelegate?

    init(view: SKView?) {
        self.view = view
    }

    func presentMainMenu() {
        // Preload main menu assets
        AssetProvider.Instance.preloadMainMenuAssets()

        let scene = MainMenuScene(size: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight))
        present(scene: scene)
    }

    func presentLevel() {
        // Preload level assets
        AssetProvider.Instance.preloadLevelAssets()

        let scene = LevelScene(size: CGSize(width: GameConstants.targetWidth, height: GameConstants.targetHeight))
        present(scene: scene)
    }

    private func present(scene: SKScene, transition: SKTransition = SKTransition.crossFade(withDuration: 0.5)) {
        if var coordinated = scene as? CoordinatedScene {
            coordinated.coordinator = self
        }
        scene.scaleMode = (scene as? SceneScaleModeProviding)?.preferredScaleMode ?? .aspectFill
        delegate?.sceneCoordinator(self, willPresent: scene)
        view?.presentScene(scene, transition: transition)
    }
}

import SpriteKit

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
        if let baseScene = scene as? BaseScene {
            baseScene.coordinator = self
        }
        delegate?.sceneCoordinator(self, willPresent: scene)
        view?.presentScene(scene, transition: transition)
    }
}

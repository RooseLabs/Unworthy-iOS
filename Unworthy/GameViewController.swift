import UIKit
import SpriteKit

class GameViewController: UIViewController {
    private var coordinator: SceneCoordinator?
    private let hudOverlayView = LevelHUDOverlayView()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        hudOverlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hudOverlayView)
        NSLayoutConstraint.activate([
            hudOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hudOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hudOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            hudOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hudOverlayView.isHidden = true
        hudOverlayView.onPauseRequested = { [weak self] in
            self?.toggleScenePause()
        }

        coordinator = SceneCoordinator(view: skView)
        coordinator?.delegate = self
        coordinator?.presentMainMenu()
    }

    private func toggleScenePause() {
        guard let skView = view as? SKView else { return }
        guard let scene = skView.scene else { return }
        scene.isPaused.toggle()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

extension GameViewController: SceneCoordinatorDelegate {
    func sceneCoordinator(_ coordinator: SceneCoordinator, willPresent scene: SKScene) {
        if let levelScene = scene as? LevelScene {
            hudOverlayView.configureForLevel()
            levelScene.inputState = hudOverlayView.inputState
        } else {
            hudOverlayView.configureForMenu()
        }
    }
}

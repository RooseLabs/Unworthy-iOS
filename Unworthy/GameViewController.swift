import UIKit
import SpriteKit

extension Notification.Name {
    static let levelDidRequestResume = Notification.Name("LevelScene.didRequestResume")
}

class GameViewController: UIViewController {
    private var coordinator: SceneCoordinator?
    private let hudOverlayView = HUDView()
    private let keyboardController = KeyboardController()
    private var resumeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        skView.showsFPS = GameConstants.debug
        skView.showsNodeCount = GameConstants.debug

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

        keyboardController.inputState = hudOverlayView.inputState
        keyboardController.onPauseToggleRequested = { [weak self] in
            guard let skView = self?.view as? SKView,
                  skView.scene is LevelScene else { return }
            self?.toggleScenePause()
        }

        resumeObserver = NotificationCenter.default.addObserver(
            forName: .levelDidRequestResume,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self,
                  let scene = (self.view as? SKView)?.scene,
                  scene.isPaused else { return }
            self.toggleScenePause()
        }

        coordinator = SceneCoordinator(view: skView)
        coordinator?.delegate = self
        coordinator?.presentMainMenu()
    }

    deinit {
        if let observer = resumeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func toggleScenePause() {
        guard let skView = view as? SKView,
              let scene = skView.scene as? BaseScene else { return }
        if scene.isPaused {
            scene.resume()
            hudOverlayView.setGameplayControlsHidden(false)
            keyboardController.isEnabled = (scene is LevelScene)
        } else {
            guard scene.canPause else { return }
            scene.pause()
            hudOverlayView.setGameplayControlsHidden(true)
            keyboardController.isEnabled = false
        }
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
            keyboardController.isEnabled = true
        } else {
            hudOverlayView.configureForMenu()
            keyboardController.isEnabled = false
        }
    }
}

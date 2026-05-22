import UIKit
import SpriteKit

extension Notification.Name {
    static let levelDidRequestResume = Notification.Name("LevelScene.didRequestResume")
}

class GameViewController: UIViewController {
    private var coordinator: SceneCoordinator?
    private let touchControlsView = TouchControlsView()
    private let keyboardController = KeyboardController()
    private var resumeObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        skView.showsFPS = GameConstants.debug
        skView.showsNodeCount = GameConstants.debug

        touchControlsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(touchControlsView)
        NSLayoutConstraint.activate([
            touchControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            touchControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            touchControlsView.topAnchor.constraint(equalTo: view.topAnchor),
            touchControlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        touchControlsView.isHidden = true
        touchControlsView.onPauseRequested = { [weak self] in
            self?.toggleScenePause()
        }
        touchControlsView.onTouchInteraction = { [weak self] in
            self?.activeLevelScene?.markTouchInteraction()
        }

        keyboardController.inputState = touchControlsView.inputState
        keyboardController.onPauseToggleRequested = { [weak self] in
            guard let skView = self?.view as? SKView,
                  skView.scene is LevelScene else { return }
            self?.toggleScenePause()
        }
        keyboardController.onKeyboardInteraction = { [weak self] in
            self?.activeLevelScene?.markKeyboardInteraction()
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

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        propagateSafeAreaInsetsToScene()
    }

    private func propagateSafeAreaInsetsToScene() {
        guard let scene = (view as? SKView)?.scene as? BaseScene else { return }
        scene.safeAreaInsets = view.safeAreaInsets
    }

    private var activeLevelScene: LevelScene? {
        (view as? SKView)?.scene as? LevelScene
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
            touchControlsView.configureForLevel()
            keyboardController.isEnabled = (scene is LevelScene)
        } else {
            guard scene.canPause else { return }
            scene.pause()
            touchControlsView.configureForMenu()
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
        if let baseScene = scene as? BaseScene {
            baseScene.safeAreaInsets = view.safeAreaInsets
        }
        if let levelScene = scene as? LevelScene {
            touchControlsView.configureForLevel()
            levelScene.inputState = touchControlsView.inputState
            levelScene.onTouchControlsAlphaChanged = { [weak self] alpha in
                self?.touchControlsView.alpha = alpha
            }
            touchControlsView.alpha = 1
            keyboardController.isEnabled = true
        } else {
            touchControlsView.configureForMenu()
            keyboardController.isEnabled = false
        }
    }
}

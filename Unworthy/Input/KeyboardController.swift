import CoreGraphics
import Foundation
import GameController

final class KeyboardController {
    weak var inputState: LevelInputState?
    var onPauseToggleRequested: (() -> Void)?

    var isEnabled = false {
        didSet { if !isEnabled { reset() } }
    }

    private var leftPressed = false
    private var rightPressed = false
    private var connectObserver: NSObjectProtocol?

    init() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let keyboard = note.object as? GCKeyboard,
                  let input = keyboard.keyboardInput else { return }
            self?.bind(input)
        }
        if let input = GCKeyboard.coalesced?.keyboardInput {
            bind(input)
        }
    }

    deinit {
        if let observer = connectObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func bind(_ input: GCKeyboardInput) {
        input.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            self?.handle(keyCode: keyCode, pressed: pressed)
        }
    }

    private func handle(keyCode: GCKeyCode, pressed: Bool) {
        if keyCode == .escape {
            if pressed { onPauseToggleRequested?() }
            return
        }
        guard isEnabled else { return }
        switch keyCode {
        case .keyA, .leftArrow:
            leftPressed = pressed
            pushAxis()
        case .keyD, .rightArrow:
            rightPressed = pressed
            pushAxis()
        case .spacebar:
            if pressed { inputState?.requestJump() }
        case .keyJ, .keyZ:
            if pressed { inputState?.requestAttack() }
        default:
            break
        }
    }

    private func pushAxis() {
        let x: CGFloat = (rightPressed ? 1 : 0) - (leftPressed ? 1 : 0)
        inputState?.setMovementAxis(CGVector(dx: x, dy: 0))
    }

    private func reset() {
        if leftPressed || rightPressed {
            leftPressed = false
            rightPressed = false
            inputState?.setMovementAxis(.zero)
        }
    }
}

import SwiftUI
import UIKit

/// Lets the custom tab bar hide while the keyboard is on screen.
final class KeyboardObserver: ObservableObject {
    @Published private(set) var isVisible = false
    private var tokens: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        tokens.append(center.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isVisible = true
        })
        tokens.append(center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isVisible = false
        })
    }

    deinit {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
    }
}

/// Keeps the edge swipe-back gesture working while the system navigation bar is hidden
/// (CheKita uses its own headers with a round back button).
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

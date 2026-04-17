import UIKit

/// 键盘避让工具，监听键盘弹起/收起事件，自动调整 scrollView 的 contentInset 并将激活的输入框滚动到可见区域
enum KeyboardHelper {

    /// 注册键盘通知，返回两个 observer 对象，需在 deinit 或 viewWillDisappear 中调用 unregister 移除
    static func register(
        scrollView: UIScrollView,
        in viewController: UIViewController
    ) -> [NSObjectProtocol] {
        let showObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                  let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
            else { return }

            // 将键盘 frame 从屏幕坐标转换到 scrollView 坐标
            let keyboardFrameInView = viewController.view.convert(endFrame, from: nil)
            let scrollViewBottom = scrollView.frame.maxY
            let overlap = scrollViewBottom - keyboardFrameInView.origin.y
            let bottomInset = max(overlap, 0)

            let options = UIView.AnimationOptions(rawValue: curve << 16)
            UIView.animate(withDuration: duration, delay: 0, options: options) {
                scrollView.contentInset.bottom = bottomInset
                scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
            }

            // 将当前激活的输入框滚动到可见区域
            if let activeField = viewController.view.findFirstResponder() {
                let fieldFrame = activeField.convert(activeField.bounds, to: scrollView)
                // 多留 20pt 间距
                let visibleRect = fieldFrame.insetBy(dx: 0, dy: -20)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    scrollView.scrollRectToVisible(visibleRect, animated: true)
                }
            }
        }

        let hideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { notification in
            let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval) ?? 0.25
            let curve = (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7

            let options = UIView.AnimationOptions(rawValue: curve << 16)
            UIView.animate(withDuration: duration, delay: 0, options: options) {
                scrollView.contentInset.bottom = 0
                scrollView.verticalScrollIndicatorInsets.bottom = 0
            }
        }

        return [showObserver, hideObserver]
    }

    /// 移除键盘通知 observer
    static func unregister(_ observers: [NSObjectProtocol]) {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - UIView 查找第一响应者

private extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for sub in subviews {
            if let found = sub.findFirstResponder() { return found }
        }
        return nil
    }
}

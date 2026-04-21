import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        // 恢复登录状态
        AuthManager.shared.loadFromKeychain()

        // 启动时加载分类（不阻塞UI）
        Task {
            try? await CategoryService.fetchCategories()
        }

        // 监听认证过期通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthExpired),
            name: AuthManager.authDidExpireNotification,
            object: nil
        )

        // 根据登录状态决定首屏
        if AuthManager.shared.isAuthenticated {
            switchToMain()
        } else {
            switchToLogin()
        }

        window?.makeKeyAndVisible()
    }

    /// 切换到主页面
    func switchToMain() {
        let tabBar = MainTabBarController()
        window?.rootViewController = tabBar
    }

    /// 切换到登录页
    func switchToLogin() {
        let nav = UINavigationController(rootViewController: LoginViewController())
        nav.navigationBar.prefersLargeTitles = false
        window?.rootViewController = nav
    }

    @objc private func handleAuthExpired() {
        switchToLogin()
    }
}

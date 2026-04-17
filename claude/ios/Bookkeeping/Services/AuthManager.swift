import UIKit

// MARK: - 认证状态管理单例

class AuthManager {
    static let shared = AuthManager()

    /// 认证过期通知名
    static let authDidExpireNotification = Notification.Name("AuthDidExpire")

    private(set) var token: String?
    private(set) var userId: Int?
    private(set) var username: String?

    var isAuthenticated: Bool { token != nil }

    private init() {}

    /// 启动时从 Keychain 恢复登录状态
    func loadFromKeychain() {
        token = KeychainHelper.loadToken()
        if token != nil {
            userId = UserDefaults.standard.integer(forKey: "auth_user_id")
            username = UserDefaults.standard.string(forKey: "auth_username")
        }
    }

    /// 登录/注册成功后保存认证信息
    func setAuth(response: AuthResponse) {
        token = response.token
        userId = response.id
        username = response.username
        KeychainHelper.saveToken(response.token)
        UserDefaults.standard.set(response.id, forKey: "auth_user_id")
        UserDefaults.standard.set(response.username, forKey: "auth_username")
    }

    /// 清除认证信息
    func logout() {
        token = nil
        userId = nil
        username = nil
        KeychainHelper.deleteToken()
        UserDefaults.standard.removeObject(forKey: "auth_user_id")
        UserDefaults.standard.removeObject(forKey: "auth_username")
    }

    /// 401 时调用：仅在已登录状态下清除认证并跳转登录页
    /// 未登录时（如登录接口返回 401）不触发跳转，由调用方自行处理错误
    func handleUnauthorized() {
        guard isAuthenticated else { return }
        logout()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.authDidExpireNotification, object: nil)
        }
    }
}

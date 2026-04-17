import Foundation

// MARK: - 认证 API

enum AuthService {
    private struct AuthBody: Encodable {
        let username: String
        let password: String
    }

    /// 登录
    static func login(username: String, password: String) async throws -> AuthResponse {
        try await APIClient.post(path: "/auth/login", body: AuthBody(username: username, password: password))
    }

    /// 注册
    static func register(username: String, password: String) async throws -> AuthResponse {
        try await APIClient.post(path: "/auth/register", body: AuthBody(username: username, password: password))
    }
}

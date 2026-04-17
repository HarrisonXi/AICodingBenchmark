import Foundation

/// 登录/注册 API 响应
struct AuthResponse: Codable {
    let id: Int
    let username: String
    let token: String
}

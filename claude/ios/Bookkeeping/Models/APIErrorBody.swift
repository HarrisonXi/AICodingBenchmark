import Foundation

/// API 错误响应信封
struct APIErrorBody: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
}

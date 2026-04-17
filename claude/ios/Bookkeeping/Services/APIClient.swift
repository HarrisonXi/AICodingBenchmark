import Foundation

// MARK: - HTTP 客户端（对标前端 http.ts）

enum APIClient {
    static let baseURL = "http://localhost:3000/api"

    /// API 错误
    struct APIError: LocalizedError {
        let status: Int
        let code: String
        let message: String
        var errorDescription: String? { message }
    }

    /// 统一响应信封
    private struct APIResponse<T: Decodable>: Decodable {
        let data: T
    }

    /// 删除接口的响应
    struct DeleteResponse: Decodable {
        let message: String
    }

    // MARK: - 核心请求方法

    static func request<T: Decodable>(
        path: String,
        method: String,
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError(status: 0, code: "INVALID_URL", message: "无效的请求地址")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 自动注入 token
        if let token = AuthManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 设置请求体
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        // 处理错误响应
        if !(200...299).contains(httpResponse.statusCode) {
            var code = "UNKNOWN_ERROR"
            var message = "请求失败 (\(httpResponse.statusCode))"
            if let errorBody = try? JSONDecoder().decode(APIErrorBody.self, from: data) {
                code = errorBody.error.code
                message = errorBody.error.message
            }
            // 401 强制退出登录
            if httpResponse.statusCode == 401 {
                AuthManager.shared.handleUnauthorized()
            }
            throw APIError(status: httpResponse.statusCode, code: code, message: message)
        }

        // 解析成功响应
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
        return apiResponse.data
    }

    // MARK: - 便捷方法

    static func get<T: Decodable>(path: String) async throws -> T {
        try await request(path: path, method: "GET")
    }

    static func post<T: Decodable>(path: String, body: any Encodable) async throws -> T {
        try await request(path: path, method: "POST", body: body)
    }

    static func put<T: Decodable>(path: String, body: any Encodable) async throws -> T {
        try await request(path: path, method: "PUT", body: body)
    }

    static func delete<T: Decodable>(path: String) async throws -> T {
        try await request(path: path, method: "DELETE")
    }
}

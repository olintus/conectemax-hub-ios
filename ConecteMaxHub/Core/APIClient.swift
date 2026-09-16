import Foundation

struct APIError: LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}
struct MessageDTO: Codable { let message: String }
struct APIClient {
    let baseURL: URL
    var session: URLSession = .shared
    func request<T: Decodable>(_ path: String, access: String? = nil) async throws -> T {
        try await send(path, method: "GET", body: Optional<String>.none, access: access)
    }

    func request<T: Decodable, Body: Encodable>(_ path: String, body: Body, access: String? = nil) async throws -> T {
        try await send(path, method: "POST", body: body, access: access)
    }

    private func send<T: Decodable, Body: Encodable>(_ path: String, method: String, body: Body?, access: String?) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError(status: 0, message: "Endereço da solicitação inválido.")
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let access { request.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization") }
        if let body { request.httpBody = try JSONEncoder().encode(body) }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError(status: 0, message: "Resposta inválida.") }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError(status: http.statusCode, message: (try? JSONDecoder().decode(MessageDTO.self, from: data).message) ?? "Não foi possível concluir a solicitação.")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

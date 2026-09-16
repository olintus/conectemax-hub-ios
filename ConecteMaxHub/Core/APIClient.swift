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
    func request<T: Decodable>(_ path: String, body: [String: String]? = nil, access: String? = nil) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = body == nil ? "GET" : "POST"
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

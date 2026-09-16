import Foundation

struct StartDTO: Decodable { let next: String; let challengeId: String?; let maskedChannel: String? }
struct GrantDTO: Decodable { let enrollmentToken: String }
struct TokenDTO: Decodable { let accessToken: String; let refreshToken: String; let expiresIn: Int }
@MainActor final class DemoAPIAuthRepository: AuthRepository {
    private let api: APIClient
    private let store: SessionStore
    private var access: String?
    private var refreshing: Task<TokenDTO, Error>?
    init(api: APIClient, store: SessionStore) { self.api = api; self.store = store }
    private func accept(_ tokens: TokenDTO) throws { try store.write(tokens.refreshToken); access = tokens.accessToken }
    func start(cpf: String) async throws -> AccessStep {
        let result: StartDTO = try await api.request("auth/start", body: ["cpf": cpf])
        return AccessStep(next: result.next, challengeID: result.challengeId, maskedChannel: result.maskedChannel)
    }
    func verify(challenge: String, code: String) async throws -> String {
        let result: GrantDTO = try await api.request("auth/verify", body: ["challengeId": challenge, "code": code]); return result.enrollmentToken
    }
    func login(cpf: String, password: String) async throws {
        let result: TokenDTO = try await api.request("auth/login", body: ["cpf": cpf, "password": password]); try accept(result)
    }
    func enroll(grant: String, password: String, confirmation: String) async throws {
        let result: TokenDTO = try await api.request("auth/enroll", body: ["enrollmentToken": grant, "password": password, "confirmation": confirmation]); try accept(result)
    }
    private func refresh() async throws {
        if let refreshing { try accept(try await refreshing.value); return }
        guard let token = try store.read() else { throw APIError(status: 401, message: "Sessão encerrada. Entre novamente.") }
        let client = api
        let task = Task<TokenDTO, Error> { try await client.request("auth/refresh", body: ["refreshToken": token]) }
        refreshing = task
        defer { refreshing = nil }
        do { try accept(try await task.value) }
        catch let error as APIError where error.status == 401 { try store.clear(); access = nil; throw error }
    }
    func restore() async throws -> Bool {
        guard try store.read() != nil else { return false }
        do { try await refresh(); return true }
        catch let error as APIError where error.status == 401 { return false }
    }
    func authorized<T: Decodable>(_ path: String) async throws -> T {
        if let access {
            do { return try await api.request(path, access: access) }
            catch let error as APIError where error.status == 401 { /* Refresh once. */ }
        }
        try await refresh()
        return try await api.request(path, access: access)
    }
    func authorized<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        if let access {
            do { return try await api.request(path, body: body, access: access) }
            catch let error as APIError where error.status == 401 { /* Refresh once. */ }
        }
        try await refresh()
        return try await api.request(path, body: body, access: access)
    }
    func logout() async throws {
        if let refresh = try store.read() { let _: MessageDTO = try await api.request("auth/logout", body: ["refreshToken": refresh]) }
        try store.clear(); access = nil
    }
    func changePassword(current: String, password: String, confirmation: String) async throws {
        let _: MessageDTO = try await authorized("auth/password", body: ["currentPassword": current, "password": password, "confirmation": confirmation])
        try store.clear(); access = nil
    }
}

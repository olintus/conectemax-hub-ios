import Foundation

struct AccessStep { let next: String; let challengeID: String?; let maskedChannel: String? }
@MainActor protocol AuthRepository {
    func start(cpf: String) async throws -> AccessStep
    func verify(challenge: String, code: String) async throws -> String
    func login(cpf: String, password: String) async throws
    func enroll(grant: String, password: String, confirmation: String) async throws
    func restore() async throws -> Bool
    func logout() async throws
    func changePassword(current: String, password: String, confirmation: String) async throws
}

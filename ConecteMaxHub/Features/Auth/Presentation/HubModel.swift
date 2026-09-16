import Foundation
import Observation

@MainActor @Observable final class HubModel {
    var stage = "restore"
    var busy = false
    var error: String?
    var channel: String?
    var hub: Hub?
    private var cpf = ""
    private var challenge = ""
    private var grant = ""
    private let auth: AuthRepository
    private let repository: HubRepository
    init(auth: AuthRepository, repository: HubRepository) { self.auth = auth; self.repository = repository }
    private func run(_ action: @escaping @MainActor () async throws -> Void) {
        guard !busy else { return }; busy = true; error = nil
        Task {
            defer { busy = false }
            do { try await action() }
            catch is CancellationError { }
            catch let apiError as APIError {
                error = apiError.message
                if apiError.status == 401 && stage == "hub" { stage = "cpf"; hub = nil }
            }
            catch { self.error = "Não foi possível conectar ou acessar a sessão. Verifique a API demo e tente novamente." }
        }
    }
    private func enter() async throws { stage = "hub"; hub = try await repository.load() }
    func restore() { run { if try await self.auth.restore() { try await self.enter() } else { self.stage = "cpf" } } }
    func start(_ cpf: String) { run { let step = try await self.auth.start(cpf: cpf); self.cpf = cpf; self.challenge = step.challengeID ?? ""; self.channel = step.maskedChannel; self.stage = step.next } }
    func verify(_ code: String) { run { self.grant = try await self.auth.verify(challenge: self.challenge, code: code); self.stage = "enroll" } }
    func login(_ password: String) { run { try await self.auth.login(cpf: self.cpf, password: password); try await self.enter() } }
    func enroll(_ password: String, _ confirmation: String) { run { try await self.auth.enroll(grant: self.grant, password: password, confirmation: confirmation); self.grant = ""; try await self.enter() } }
    func reload() { run { self.hub = try await self.repository.load() } }
    func logout() { run { try await self.auth.logout(); self.stage = "cpf"; self.hub = nil } }
    func changePassword(_ current: String, _ password: String, _ confirmation: String) {
        run { try await self.auth.changePassword(current: current, password: password, confirmation: confirmation); self.stage = "cpf"; self.hub = nil }
    }
    func restart() { guard !busy else { return }; cpf = ""; challenge = ""; grant = ""; stage = "cpf"; error = nil }
}

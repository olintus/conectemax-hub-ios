import Foundation
import Security

protocol SessionStore {
    func read() throws -> String?
    func write(_ token: String) throws
    func clear() throws
}
struct KeychainSessionStore: SessionStore {
    private let service = "br.com.conectemax.hub.session"
    private var query: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "refresh"] }
    func read() throws -> String? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data, let token = String(data: data, encoding: .utf8) else { throw StoreError(status: status) }
        return token
    }
    func write(_ token: String) throws {
        let values: [String: Any] = [kSecValueData as String: Data(token.utf8), kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        var status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
        if status == errSecItemNotFound { status = SecItemAdd(query.merging(values) { _, new in new } as CFDictionary, nil) }
        guard status == errSecSuccess else { throw StoreError(status: status) }
    }
    func clear() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw StoreError(status: status) }
    }
}
struct StoreError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? { "Não foi possível acessar a sessão segura. Desbloqueie o dispositivo e tente novamente." }
}
// A future LocalAuthentication adapter gates local access to an existing server session.
protocol LocalSessionGate { func unlock() async throws -> Bool }
